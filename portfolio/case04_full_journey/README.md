# Case 04 - Full Journey: Pipeline RevOps B2B (Lead → Contrato)

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-plpgsql-336791?logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-DAX-F2C811?logo=powerbi&logoColor=black)
![Status](https://img.shields.io/badge/status-concluído-brightgreen)
![Modelo](https://img.shields.io/badge/modelagem-Star%20Schema%20(Kimball)-blue)

Pipeline completo de dados de RevOps B2B, do lead até o contrato ativo: ingestão, tratamento de dados sujos, modelagem dimensional e um dashboard executivo com 3 páginas segmentadas por persona (Diretor Comercial, CEO, Head de Marketing).

**Dashboard publicado (Power BI Service):**
https://app.powerbi.com/view?r=eyJrIjoiMzgzZmUyYTQtYjE3Mi00Y2M2LWIxZjEtMWFjMjQ0MDU4Nzc0IiwidCI6IjY1OWNlMmI4LTA3MTQtNDE5OC04YzM4LWRjOWI2MGFhYmI1NyJ9

---

## Contexto de negócio

Uma empresa fictícia de RevOps B2B precisa consolidar dados espalhados em 5 domínios (leads, oportunidades, atividades de vendas, contratos, custos de marketing) numa única fonte de verdade, capaz de responder perguntas diferentes para três stakeholders diferentes (personas fictícias criadas para o case, com dores de negócio realistas):

> \*\*Diego, Diretor Comercial\*\* , \*"Meu maior problema hoje é que não sei onde estou perdendo negócio. Preciso entender o ciclo de cada vendedor e onde os leads estão travando no funil , se é qualificação ou é preço/concorrência. Hoje eu olho isso em planilha e perco horas toda segunda-feira."\*

> \*\*Camila, Head de Marketing\*\* , \*"Estou investindo em quatro canais e não sei qual gera receita de verdade, não só lead. Preciso conectar o lead lá no início com o contrato no final, saber o CAC real por canal, e entender sazonalidade de entrada e de conversão."\*

> \*\*Rafael, CEO\*\* , \*"Quero uma página que me dê o estado do negócio em 30 segundos: MRR, crescimento, churn, pipeline e projeção. Se algum número estiver vermelho, eu entro no detalhe com o Diretor Comercial."\*

Cada página do dashboard foi desenhada como resposta direta a um desses relatos , não como um conjunto genérico de KPIs de RevOps. A seção **Fit stakeholder × entrega**, mais abaixo, documenta esse mapeamento ponto a ponto.

A base (`revops\_enriched\_v3.sql`) tem \~600 leads, \~400 oportunidades, \~900 atividades e \~200 contratos ao longo de 18 meses, com sujeira proposital (nulos, formatos inconsistentes, datas fora de ordem) para simular um ambiente real.

---

## Arquitetura

```
public (OLTP)
     |
     ▼
staging          ← ingestão bruta, 1:1 com a origem
     |
     ▼
tratamento       ← 12 views: normalização, regras de negócio, flags de anomalia
     |
     ▼
dw               ← star schema (Kimball): 6 dimensões + 6 fatos
     |
     ▼
Power BI         ← 3 páginas por persona, DAX avançado, insights dinâmicos
```

Cada camada tem uma responsabilidade única e não pula etapa , uma regra de negócio nunca é calculada direto no DAX se ela puder ser resolvida na camada de tratamento. Essa disciplina é o que permite que qualquer ferramenta de BI futura (não só Power BI) consuma o mesmo DW sem reescrever lógica.

---

## As 10 decisões arquiteturais

Cada decisão aqui resolve um problema específico que apareceu durante a construção , não são escolhas de manual, são respostas a um problema real do case.

|#|Decisão|Problema que evita|O que demonstra|
|-|-|-|-|
|1|Schemas separados (`staging`/`tratamento`/`dw`)|Lógica de negócio misturada com ingestão bruta, dificultando debug|Separação de responsabilidades, base de qualquer pipeline auditável|
|2|TRUNCATE para dimensões pequenas, MERGE para fatos de maior volume|Overhead desnecessário de comparação linha a linha em tabelas 100% substituídas a cada carga|Decisão de performance com critério explícito, não regra genérica copiada|
|3|Chave natural em `dim\_vendedor` (sem surrogate key)|Adicionar uma chave técnica que nenhuma fato usa não agrega valor , só mais uma coluna pra manter|Saber quando *não* aplicar um padrão, e não só quando aplicar|
|4|Refatoração fato → dimensão (`fact\_oportunidades` → `dim\_oportunidades` + `fact\_oportunidades`)|Tabela fato carregando atributos descritivos junto com métricas, violando Kimball|Reconhecer e corrigir um erro de modelagem clássico antes de ele virar dívida técnica|
|5|Eliminação de referência fato-para-fato|Acoplamento entre fatos que quebra a independência de grão entre elas|Entendimento de dependência de schema, não só de sintaxe SQL|
|6|Calendário dinâmico (`generate\_series` + `EXTRACT(ISODOW)`)|Dimensão calendário hardcoded que não se atualiza sozinha com novos dados|Automação da manutenção da própria dimensão|
|7|Flag BOOLEAN + motivo VARCHAR para anomalias|Um único campo de texto não suporta múltiplos cenários de anomalia simultâneos|Modelagem pensando em como o campo será *filtrado* no BI, não só armazenado|
|8|Regras de negócio centralizadas na camada de tratamento (ex: `ciclo\_dias` não é calculado no DAX)|Duas ferramentas de BI diferentes calculando a mesma métrica de formas diferentes|Fonte única da verdade , o requisito mais citado (e mais ignorado) em times de dados|
|9|`dim\_canal` com `chave\_canal` (canal\|subcanal)|Chave composta no Power BI, que complica relacionamento e DAX|Simplificação do lado do consumo, não só do lado do banco|
|10|`fact\_leads` minimalista (id + data)|Fato carregando atributos que mudam de valor ao longo do tempo, quebrando a granularidade|Entendimento de que fato é evento, dimensão é contexto|

---

## Camada de Staging (8 tabelas)

Ingestão 1:1 com a origem, sem tratamento de regra de negócio , só tipagem e organização.

`ST\_LEADS` · `ST\_OPORTUNIDADES` · `ST\_ATIVIDADES` · `ST\_CONTRATOS` · `ST\_VENDEDOR` · `ST\_PLANOS` · `ST\_METAS` · `ST\_CUSTOS`

Orquestrada por `USP\_ST\_CARGA\_GERAL()`.

---

## Camada de Tratamento (12 views)

Onde a sujeira dos dados é resolvida e as regras de negócio ganham vida. Alguns exemplos que valem destaque:

* **`VW\_D\_LEADS`** , capitalização, e-mail/telefone padronizados, `classificacao\_score` derivada
* **`VW\_D\_CANAL`** , unifica canais vindos de leads e de custos via `UNION` (não `UNION ALL` , aqui a deduplicação é intencional)
* **`VW\_D\_CALENDARIO`** , gerada dinamicamente a partir do intervalo real dos dados (`MIN(leads)` até `MAX(contratos)`)
* **`VW\_F\_OPORTUNIDADES`** , calcula `ciclo\_dias` e sinaliza `flag\_anomalia\_data`
* **`VW\_F\_CONTRATOS`** , `flag\_anomalia` (BOOLEAN) + `motivo` (VARCHAR), cobrindo inclusive o cenário de renovação e cancelamento simultâneos

---

## Camada DW , Star Schema (11 tabelas)

**Dimensões:** `dim\_leads` · `dim\_vendedor` · `dim\_planos` · `dim\_canal` · `dim\_calendario` · `dim\_oportunidades`
**Fatos:** `fact\_leads` · `fact\_oportunidades` · `fact\_atividades` · `fact\_contratos` · `fact\_metas` · `fact\_custos`

Orquestrada por `USP\_DW\_CARGA\_GERAL()`, que respeita a ordem de dependência:

```
1. Dimensões independentes → leads, vendedores, planos, calendário, canal, metas, custos
2. Dimensão dependente     → dim\_oportunidades (depende de dim\_leads e dim\_vendedor)
3. Fato 1:1                → fact\_oportunidades (depende de dim\_oportunidades)
4. Fatos dependentes       → fact\_leads, fact\_atividades, fact\_contratos
```

---

## Dashboard Power BI - 3 páginas por persona

|Página|Persona|Foco|
|-|-|-|
|Resumo Executivo|CEO|MRR, churn, meta consolidada, insight dinâmico do mês crítico, projeção de MRR|
|Performance Comercial|Diretor Comercial|Funil safrado (com cross-filter), rank de vendedores, ICP (segmento × porte), motivo de perda|
|Marketing|Head de Marketing|CAC, qualificação e MRR por canal, ciclo por canal, sazonalidade de entrada e conversão|

Cada página tem um **insight dinâmico gerado via DAX** (`SWITCH(TRUE())`) que muda automaticamente conforme o filtro aplicado. Esses textos são propositalmente uma **ferramenta de apoio, não uma recomendação fechada** , dono, prazo e forma de execução de uma ação dependem de contexto organizacional (quem está disponível, prioridade concorrente, orçamento) que nenhum dashboard tem como inferir sozinho. O papel do insight dinâmico é apontar rápido *onde* olhar; a decisão final continua sendo humana, com quem entende a situação por completo.

### Página 1 - Resumo Executivo (Rafael, CEO)

![Resumo Executivo](images/01\_resumo\_executivo.png)

### Página 2 - Performance Comercial (Diego, Diretor Comercial)

![Performance Comercial](images/02\_performance\_comercial.png)

### Página 3 - Marketing (Camila, Head de Marketing)

![Marketing](images/03\_marketing.png)

**Interatividade como resposta a necessidade real, não só recurso do BI:**

* Na página Comercial, clicar em qualquer estágio do funil filtra o restante da página (motivo de desqualificação, motivo de perda por concorrente), resolve diretamente o pedido do Diretor Comercial de conectar "onde trava" com "por que trava" sem precisar da adição de mais um visual
* O tooltip do "Rank por Score" traz ciclo de dias, ticket médio, winrate e MRR ao passar o mouse, sem poluir a visão inicial
* Na página de Marketing, clicar em um mês filtra a tabela de canais, revelando winrate e demais métricas daquele recorte, a forma de conectar "quando entra" com "quando converte" que a Head de Marketing pediu
* O tooltip da visão safrada traz ciclo de dias por mês

**Achado analítico de destaque:** o dashboard revelou que leads classificados como score **"Alto"** têm o **menor** winrate entre as 4 faixas de classificação (53,45%), enquanto leads **"Médio"** convertem mais (60,23%) , um resultado contraintuitivo que indica necessidade de recalibração do modelo de scoring. Esse tipo de achado é o que diferencia um dashboard descritivo de uma ferramenta de decisão.

**Dashboard publicado (view-only, sem download do modelo):** o link no topo deste README leva à versão publicada no Power BI Service , permite navegar e interagir com os 3 painéis sem expor o arquivo `.pbix` de origem.

---

## Fit stakeholder × entrega

Além da nota técnica, cada página foi avaliada contra o relato original do stakeholder , a régua real de um dashboard não é "tem KPI bonito", é "responde ao que foi pedido".

**Diego (Comercial):** ciclo, winrate e ticket por vendedor numa tabela só; funil safrado com cross-filter ligando estágio de travamento a motivo (qualificação vs. preço/concorrência); tooltip com profundidade analítica sob demanda.

**Camila (Marketing):** tabela por canal conectando lead → MRR → CAC → churn na mesma linha; ciclo de dias por mês e por canal no tooltip para entender defasagem de conversão; mapa de leads por estado relido como leitura de **onde é mais fácil entrar no mercado** (baixa saturação de esforço/concorrência), não só densidade de lead.

**Rafael (CEO):** KPIs + banner de insight cobrem o "30 segundos"; scatter com toggle Squad/Vendedor funciona como preparo de conversa com o Diretor Comercial, não como ferramenta de decisão solo; projeção de MRR via run-rate de 3 meses (sem ML , desproporcional ao escopo e ao pedido real do stakeholder).

---

## Desafios técnicos reais (e como foram resolvidos)

Documentar só o resultado final esconde a parte mais valiosa do processo. Estes foram os 3 problemas reais encontrados em revisão e a correção aplicada:

1. **Erro de sintaxe em CTE** (`VW\_F\_LEADS`) , um `;` posicionado antes do fechamento do CTE quebrava a view. Corrigido movendo o `;` para o fim da query.
2. **`TRUNCATE ... CASCADE` como risco silencioso** , `dim\_leads` e `dim\_vendedor` são referenciadas por FK em `dim\_oportunidades` e `fact\_metas`. Um `TRUNCATE` simples falha por violação de integridade referencial; um `TRUNCATE ... CASCADE` resolve o erro mas apaga em cascata todas as tabelas dependentes , seguro apenas se toda a carga for sempre executada via `USP\_DW\_CARGA\_GERAL()` de ponta a ponta. Resolvido substituindo por `MERGE` (upsert + delete de órfãos) nas duas dimensões referenciadas, mantendo `TRUNCATE` simples nas dimensões sem dependentes (mais eficiente onde é seguro).
3. **Referência fato-para-fato não documentada** , `fact\_atividades` referenciava `fact\_oportunidades` diretamente, contradizendo a decisão arquitetural #5 (fato-para-fato eliminado). Corrigido apontando a FK para `dim\_oportunidades`, restaurando a consistência entre documentação e código.
4. **Medida de projeção de MRR sem quebrar a formatação condicional** , o desafio: adicionar uma projeção de MRR ao gráfico principal sem perder a cor condicional por atingimento de meta (aplicada só na série de barras) e sem distorcer o dado real. A primeira versão calculava o MRR base no contexto de linha errado (retornando zero no mês projetado); depois de corrigido, o ponto isolado não tinha como virar linha (Power BI não desenha traço com 1 ponto só); a solução final usa uma medida com `SWITCH(TRUE())` que repete o MRR real numa janela de 3 meses (para dar "início" visual à linha) e calcula a projeção via run-rate de MoM médio apenas no mês seguinte ao último dado real , sem machine learning, proporcional ao pedido do stakeholder ("saber se estamos crescendo", não uma previsão estatística precisa).

---

## Como executar

```sql
-- 1. Carrega a camada de staging (ingestão bruta)
CALL USP\_ST\_CARGA\_GERAL();

-- 2. Carrega o DW (dimensões → dimensão dependente → fatos)
CALL USP\_DW\_CARGA\_GERAL();
```

Testado com execução dupla consecutiva para garantir idempotência (nenhuma procedure depende de o banco estar vazio para rodar corretamente).

---

## Stack técnica

* **Banco:** PostgreSQL (plpgsql , procedures, views, MERGE)
* **Modelagem:** Star Schema (Kimball)
* **BI:** Power BI (DAX avançado , RANKX, ALLSELECTED, SWITCH(TRUE()))
* **Documentação:** `BUSINESS\_RULES.md` (PT/EN)

---

## Autor

**Gabriel Cintra** , Analista de Dados Sênior em transição para Analytics Engineer
[LinkedIn](https://linkedin.com/in/gabriel-cintra-power-bi) · [GitHub](https://github.com/gcintra9/gabriel-ae-journey)

