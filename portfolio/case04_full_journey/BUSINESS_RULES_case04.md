# Case 04 - Full Journey - Regras de Negócio dos Dados

## Última atualização: 08/07/2026 (auditoria técnica pós-entrega - ver seção 8)

## Visão Geral

Sistema RevOps de uma empresa SaaS B2B simulando o funil completo de aquisição e retenção de clientes: captação de leads, qualificação, abertura de oportunidades comerciais, atividades de relacionamento (reuniões, ligações), fechamento de contratos e acompanhamento de NPS.

O case foi desenvolvido a partir de uma reunião de discovery com Diego, Diretor Comercial, cujas dores principais são: falta de visibilidade do funil por etapa, ausência de comparação de performance entre vendedores, e dificuldade em identificar o perfil ideal de cliente (ICP) que converte melhor.

**Arquitetura de dados:**

```
public (OLTP)  →  staging (cópia fiel)  →  tratamento (views com regras)  →  dw (star schema)
```

\---

## 1\. Diagrama de Entidades

```
dim\_leads (1)───<(N) dim\_oportunidades ───<(1) fact\_oportunidades
                          │
                          ├───<(N) fact\_atividades
                          │
                          └───<(N) fact\_contratos

dim\_vendedor (1)───<(N) dim\_oportunidades  \[relacionamento via nome , chave natural]
dim\_planos   (1)───<(N) fact\_contratos     \[relacionamento via nome , chave natural]
```

**Observação de modelagem:** `fact\_oportunidades` tem relacionamento 1:1 com `dim\_oportunidades`, cada oportunidade gera exatamente uma linha de métricas. Essa separação entre dimensão (atributos descritivos) e fato (métricas) foi uma refatoração consciente: inicialmente todos os atributos estavam em uma única `fact\_oportunidades`, mas isso gerava uma referência de **fato para fato** em `fact\_contratos` (que referenciava `fact\_oportunidades.id`), o que não é o padrão recomendado em star schema (Kimball). A separação resolveu isso , agora `fact\_contratos` referencia `dim\_oportunidades`, mantendo o modelo em estrela correto.

\---

## 2\. Decisões Arquiteturais

### 2.1 Estratégia de carga: TRUNCATE vs MERGE

|Tipo de tabela|Estratégia|Motivo|
|-|-|-|
|Dimensões pequenas (`dim\_vendedor`, `dim\_planos`)|TRUNCATE + INSERT|Volume baixo, recarga total é instantânea, simplicidade|
|Dimensões com mais atributos (`dim\_leads`, `dim\_oportunidades`)|TRUNCATE + INSERT|Mesma lógica , ainda são volumes administráveis|
|Fatos que crescem (`fact\_oportunidades`, `fact\_atividades`, `fact\_contratos`)|MERGE (upsert)|Volume cresce continuamente; processar só o delta evita reprocessamento caro em escala|

A decisão foi tomada por **volume esperado de crescimento**, não pela camada (staging vs DW) , a mesma lógica se aplica em ambas as camadas, mantendo consistência arquitetural ponta a ponta.

> \*\*Atualização pós-auditoria (ver seção 8):\*\* a regra acima precisou de uma exceção. `dim\_leads` e `dim\_vendedor` são referenciadas por FK em `dim\_oportunidades` (e `dim\_vendedor` também em `fact\_metas`), então `TRUNCATE` simples nessas duas passou a falhar por violação de integridade referencial a partir da segunda carga completa do pipeline , independente do volume. Ambas foram migradas para `MERGE`, mantendo `TRUNCATE` nas demais dimensões sem dependentes.

### 2.2 Chave natural vs Surrogate Key

A `dim\_vendedor` usa `vendedor` (texto) como chave primária, em vez de um ID numérico (`SERIAL`) gerado artificialmente.

**Trade-off consciente:** um surrogate key só agrega valor real se a fato também for ajustada para referenciar por ID em vez de texto, caso contrário, vira uma coluna redundante sem uso real no JOIN. Como as views da fato não foram modeladas para esse padrão, a chave natural foi mantida por ser mais simples e igualmente funcional para o escopo do case.

**Evolução possível:** se o modelo crescer e a fato passar a referenciar por ID, a migração para surrogate key (com `ROW\_NUMBER()` ou `SERIAL`) seria o próximo passo natural, incluindo o padrão de **membro desconhecido** (linha com `id = -1` para casos sem correspondência).

### 2.3 Referência entre fatos , refatoração de `fact\_oportunidades`

**Problema identificado:** a primeira versão de `fact\_oportunidades` continha tanto atributos descritivos (vendedor, stage, moeda, motivo\_perda, concorrente) quanto métricas (valor\_mrr, ciclo\_dias). Isso fazia com que `fact\_contratos.oportunidade\_id` referenciasse diretamente `fact\_oportunidades.id` , uma referência de fato para fato, fora do padrão star schema.

**Solução aplicada:** os atributos descritivos foram extraídos para uma nova dimensão (`dim\_oportunidades`), e a `fact\_oportunidades` foi reduzida a métricas puras (`ciclo\_dias`, `flag\_anomalia\_data`, `valor\_mrr`, `valor\_anual`, `qtd\_reunioes`), com relacionamento 1:1 (`id` é PK e FK simultaneamente para `dim\_oportunidades`). A `fact\_contratos` passou a referenciar `dim\_oportunidades`, eliminando a dependência fato-para-fato.

> \*\*Atualização pós-auditoria (ver seção 8):\*\* em revisão de código, `fact\_atividades.oportunidade\_id` foi encontrada ainda referenciando `fact\_oportunidades.id` , a refatoração acima havia sido aplicada em `fact\_contratos`, mas não em `fact\_atividades`. Corrigido para referenciar `dim\_oportunidades.id`, alinhando a implementação com a regra já documentada nesta seção.

\---

## 3\. Regras por Tabela

### 3.1 `staging.st\_leads` → `dim\_leads`

|Campo|Regra de Negócio|Problema / Anomalia|
|-|-|-|
|`id`|PK do lead. Nunca NULL.|,|
|`nome`|Nome do lead.|Inconsistência de capitalização , tratado com `INITCAP(TRIM())`.|
|`email`|Email de contato.|Formatos inválidos (sem `@`), espaços em branco, NULL. Validado com `email NOT LIKE '%@%.%'`.|
|`telefone`|Telefone de contato.|4+ formatos coexistem: `(81) 9XXXX-XXXX`, `+55 81 9XXXXXXXX`, `819XXXXXXXX`. Tamanho de campo na staging precisou ser ajustado de `VARCHAR(15)` para `VARCHAR(30)` após erro de truncamento , lição: sempre validar tamanho real da fonte via `information\_schema` antes de definir o schema da staging.|
|`lead\_score`|Score de 0 a 100.|Pode ser NULL.|
|`status`|Valores: `novo`, `qualificado`, `desqualificado`.|,|
|`motivo\_perda`|Preenchido apenas quando `status = 'desqualificado'`.|NULL quando não desqualificado , tratado como `'Sem Perda'` na view.|

**Tratamentos aplicados em `tratamento.VW\_D\_LEADS`:**

* `INITCAP(TRIM())` em todos os campos de texto livre (nome, empresa, cargo, segmento, porte, cidade, país)
* `UPPER(TRIM())` em estado (padrão 2 letras maiúsculas)
* `LOWER(TRIM())` em email
* Classificação de email: `'Não informado'` / `'E-mail inválido'` / email normalizado
* Classificação de telefone por comprimento (após remoção de `-`), com fallback `'Formato inválido'`
* `classificacao\_score`: faixas Alto (≥80) / Médio (≥50) / Baixo (≥20) / Sem score
* `motivo\_perda`: distinção entre `'Não informado'` (desqualificado sem motivo) e `'Sem Perda'` (não desqualificado)

\---

### 3.2 `staging.st\_oportunidades` → `dim\_oportunidades` + `fact\_oportunidades`

|Campo|Regra de Negócio|Problema / Anomalia|
|-|-|-|
|`id`|PK da oportunidade.|,|
|`lead\_id`|FK para leads.|,|
|`vendedor`|Responsável comercial.|Extraído também para `dim\_vendedor` como chave natural.|
|`data\_abertura` / `data\_fechamento`|`data\_fechamento` é NULL enquanto a oportunidade está em aberto.|Alguns registros têm `data\_fechamento < data\_abertura` , anomalia real, capturada em `flag\_anomalia\_data`.|
|`stage`|Valores: `reuniao\_agendada`, `proposta\_enviada`, `negociacao`, `fechado\_ganho`, `fechado\_perdido`.|,|
|`valor\_mrr` / `valor\_anual`|Valor da oportunidade.|\~2,6% da base está em moeda USD, não BRL , decisão de manter a coluna `moeda` em vez de excluir, permitindo segmentação/exclusão na análise.|
|`concorrente`|Pode estar preenchido mesmo em oportunidades **ganhas** , permite análise de win/loss por concorrente.|,|
|`numero\_reunioes`|Quantidade de reuniões realizadas.|,|

**Coluna calculada , `ciclo\_dias` (em `VW\_F\_OPORTUNIDADES`):**

```sql
CASE 
    WHEN data\_fechamento IS NOT NULL 
    THEN data\_fechamento - data\_abertura 
    ELSE CURRENT\_DATE - data\_abertura    -- oportunidade ainda aberta, conta até hoje
END
```

Decisão de negócio: essa lógica precisa ser **única e centralizada** na camada de tratamento , se deixada para cálculo em DAX no Power BI, diferentes dashboards poderiam implementar a regra de forma diferente (ex: ignorar oportunidades abertas), gerando métricas divergentes para a mesma pergunta de negócio.

**Coluna de qualidade , `flag\_anomalia\_data`:**

```sql
CASE WHEN data\_fechamento < data\_abertura THEN TRUE ELSE FALSE END
```

Calculada na camada de tratamento (não no DW) porque é onde as demais regras de qualidade já são aplicadas , mantém uma única fonte de lógica de tratamento.

**Tratamentos em `VW\_D\_OPORTUNIDADES`:**

* `motivo\_perda`: 3 cenários , `'Não Informado'` (perdido sem motivo) / motivo real / `'Sem Perda'` (não perdido)
* `concorrente`: 3 cenários , `'Não Informado'` (perdido sem concorrente) / concorrente real (ganho ou perdido) / `'Sem Concorrente'`

\---

### 3.3 `staging.st\_atividades` → `fact\_atividades`

|Campo|Regra de Negócio|Problema / Anomalia|
|-|-|-|
|`compareceu`|BOOLEAN , se o lead compareceu à atividade.|Pode ser NULL combinado com `duracao\_min` também NULL.|
|`duracao\_min`|Duração em minutos.|NULL quando não há registro de tempo.|

**Coluna calculada , `classificacao\_duracao`:**

```sql
CASE
    WHEN compareceu = TRUE AND duracao\_min IS NULL THEN 'Não Informado'
    WHEN duracao\_min >= 90 THEN 'Muito Longa'
    WHEN duracao\_min >= 60 THEN 'Longa'
    WHEN duracao\_min >= 30 THEN 'Normal'
    WHEN duracao\_min >= 0  THEN 'Curta'
    ELSE 'Não Compareceu'
END
```

\---

### 3.4 `staging.st\_contratos` → `fact\_contratos`

|Campo|Regra de Negócio|Problema / Anomalia|
|-|-|-|
|`data\_inicio`|Início do contrato.|Alguns registros têm `data\_inicio` anterior ao fechamento da oportunidade correspondente , anomalia real (contrato não pode começar antes de a venda fechar).|
|`data\_cancelamento`|NULL quando contrato está ativo.|,|
|`nps\_score`|Escala 0–10.|Existem registros com valor `99` (fora do range) , tratado como `'Score inválido'`, distinto de NULL (`'Não Informado'`).|
|`motivo\_cancelamento`|Preenchido apenas quando há cancelamento.|Distinção entre `'Não Informado'` (cancelado sem motivo) e `'Cliente Ativo'` (não cancelado).|

**Coluna de qualidade , `flag\_anomalia\_data` + `motivo\_anomalia\_data`:**

Decisão de design: ao contrário de `fact\_oportunidades` (que usa só BOOLEAN), aqui foram criadas **duas colunas** , uma BOOLEAN para filtro rápido no Power BI, outra VARCHAR descritiva para investigação. Justificativa: contratos têm 3 cenários distintos de anomalia (vs. 1 único cenário em oportunidades), tornando a descrição textual mais valiosa para auditoria.

```sql
-- flag\_anomalia\_data (BOOLEAN)
CASE
    WHEN data\_renovacao < data\_inicio THEN TRUE
    WHEN data\_cancelamento < data\_inicio THEN TRUE
    WHEN data\_renovacao IS NOT NULL AND data\_cancelamento IS NOT NULL THEN TRUE
    ELSE FALSE
END

-- motivo\_anomalia\_data (VARCHAR)
CASE
    WHEN data\_renovacao < data\_inicio THEN 'Renovação anterior ao início'
    WHEN data\_cancelamento < data\_inicio THEN 'Cancelamento anterior ao início'
    WHEN data\_renovacao IS NOT NULL AND data\_cancelamento IS NOT NULL 
        THEN 'Contrato com renovação e cancelamento simultâneos'
    ELSE 'Sem Flag'
END
```

**Escala NPS:**

```sql
CASE
    WHEN nps\_score IS NULL THEN 'Não Informado'
    WHEN nps\_score > 10    THEN 'Score inválido'
    WHEN nps\_score >= 9    THEN 'Promotor'
    WHEN nps\_score >= 7    THEN 'Neutro'
    WHEN nps\_score >= 0    THEN 'Detrator'
    ELSE 'Não Informado'
END
```

\---

## 4\. Flags de Qualidade , Resumo

|Flag|Tabela|Tipo|Condição|
|-|-|-|-|
|`flag\_anomalia\_data`|fact\_oportunidades|Anomalia|`data\_fechamento < data\_abertura`|
|`flag\_anomalia\_data`|fact\_contratos|Anomalia|Ver 3 cenários em `motivo\_anomalia\_data`|
|Email inválido|dim\_leads (view)|Qualidade|`email NOT LIKE '%@%.%'` ou NULL|
|Telefone inválido|dim\_leads (view)|Qualidade|Comprimento fora dos padrões mapeados|
|NPS inválido|fact\_contratos|Qualidade|`nps\_score > 10`|

\---

## 5\. Cálculos de Negócio

### 5.1 Ciclo de Fechamento

```
ciclo\_dias = data\_fechamento - data\_abertura          (se fechada)
ciclo\_dias = CURRENT\_DATE - data\_abertura              (se em aberto)
```

Centralizado na camada de tratamento para garantir consistência entre todos os consumidores do dado.

### 5.2 Classificação de Score de Lead

```
Alto: lead\_score >= 80
Médio: lead\_score >= 50
Baixo: lead\_score >= 20
Sem score: lead\_score IS NULL ou < 20
```

### 5.3 Escala NPS (padrão de mercado)

```
Promotor: 9–10
Neutro: 7–8
Detrator: 0–6
```

\---

## 6\. Roteiro de EDA aplicado

1. Inventário de tabelas via `information\_schema.tables`
2. Inspeção de schema (PK, FK, tipos) via `information\_schema.columns` cruzado com `table\_constraints`
3. Seleção de colunas relevantes por stakeholder (Diego , Diretor Comercial), eliminando colunas de outro domínio (canal/UTM pertencem à visão de Marketing)
4. Verificação de moeda na base de oportunidades , decisão de manter coluna em vez de assumir uniformidade
5. Erro real de schema detectado em produção: `VARCHAR(15)` insuficiente para telefone , corrigido após validação com `MAX(LENGTH())`

\---

## 7\. Evolução Futura (não implementada neste case)

* Migração de chave natural para surrogate key em `dim\_vendedor`, com padrão de membro desconhecido (`id = -1`)
* Criação de `dim\_data` para suportar análise temporal completa (trimestre, dia da semana, dia útil)
* Particionamento de fatos por data, caso o volume cresça significativamente
* Testes automatizados (dbt-style) validando as flags de anomalia como parte do pipeline de CI

\---

## 8\. Registro de Revisão Técnica (auditoria pós-entrega)

Após a conclusão inicial do case (30/06/2026), uma auditoria de código encontrou 3 divergências entre o que estava documentado/planejado e o que estava efetivamente implementado. Registradas aqui para manter rastreabilidade entre intenção e execução.

|#|Encontrado em|Divergência|Correção aplicada|
|-|-|-|-|
|1|`tratamento.VW\_F\_LEADS`|Erro de sintaxe: `;` posicionado antes do fechamento do CTE, impedindo a view de compilar|`;` movido para o fim da query|
|2|`dw.dim\_leads`, `dw.dim\_vendedor`|`TRUNCATE` simples (sem `CASCADE`) falha a partir da 2ª carga completa, pois ambas são referenciadas por FK (`dim\_oportunidades.lead\_id`, `dim\_oportunidades.vendedor`, `fact\_metas.vendedor`) , violação de integridade referencial independente do volume, o que não estava previsto na regra da seção 2.1|Migradas para `MERGE` (upsert + `DELETE` de órfãos via `WHEN NOT MATCHED BY SOURCE`), preservando `TRUNCATE` nas dimensões sem dependentes|
|3|`dw.fact\_atividades`|`oportunidade\_id` referenciava `fact\_oportunidades.id` , contradizendo a regra já documentada na seção 2.3 (fato-para-fato eliminado)|FK corrigida para `dim\_oportunidades.id`|

Testado com execução dupla consecutiva (`CALL USP\_ST\_CARGA\_GERAL(); CALL USP\_DW\_CARGA\_GERAL();` duas vezes seguidas no mesmo banco) para confirmar idempotência após as correções.

