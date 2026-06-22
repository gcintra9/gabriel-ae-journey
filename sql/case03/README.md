# Case SQL 03 → Análise de Performance Comercial (RevOps)

**Objetivo:** Construir análises analíticas sobre um funil de vendas B2B, desde métricas básicas de negócio até detecção de anomalias de dados e análise de coorte, utilizando SQL avançado com CTEs, window functions e lógica de qualidade de dados.

**Base de dados:** RevOps v2: \~500 leads, \~350 oportunidades, \~800 atividades, \~200 contratos | 18 meses (Jan/2025 – Jun/2026)

\---

## Conceitos aplicados

|Conceito|Questões|
|-|-|
|Agregações com FILTER|Q1, Q2, Q5, Q10, Q11|
|CTEs encadeadas|Q8, Q9, Q11|
|Window Functions (LAG, DENSE\_RANK, SUM OVER, AVG OVER)|Q2, Q7, Q8|
|NULLIF para divisão segura|Q5, Q8, Q9|
|UNION ALL para funil em linhas|Q11|
|Detecção de anomalias com CASE WHEN|Q12|
|Análise de coorte|Q10|

\---

## Nível 1 - Aquecimento

### Q1 - Ticket médio por segmento

Identifica quais segmentos de mercado geram maior receita recorrente por contrato.
Decisão: `HAVING COUNT > 5` para excluir segmentos com volume insuficiente para análise estatística.

### Q2 - Evolução mensal de leads em 2025

Além do volume mensal, inclui breakdown por status (qualificado/desqualificado) e acumulado com `SUM() OVER(ORDER BY mes)`.
Decisão: `TO\_CHAR(TO\_DATE(mes::text, 'MM'), 'Mon')` para formatar número do mês como abreviação legível.

### Q3 - Ciclo médio de fechamento por vendedor

Calcula o tempo médio entre abertura e fechamento considerando apenas oportunidades encerradas.
Decisão: filtro `IN ('fechado\_ganho', 'fechado\_perdido')` para excluir oportunidades ainda em aberto que distorceriam a média.

\---

## Nível 2 - Regras de negócio

### Q4 - Leads sem atividades registradas

Identifica oportunidades que nunca tiveram nenhuma interação registrada, um sinal de processo comercial falho.
Decisão: `LEFT JOIN + WHERE IS NULL` para detectar ausência de relacionamento, semanticamente mais claro que `NOT EXISTS` nesse contexto.

### Q5 - Performance consolidada por vendedor

Visão 360 do vendedor: total de oportunidades, ganhas, perdidas, win rate e MRR ativo em uma única query.
Decisão: `NULLIF` no denominador do win rate para evitar divisão por zero quando vendedor só tem oportunidades em aberto. Win rate calculado sobre fechadas (ganhas + perdidas), excluindo em aberto.

### Q6 - Contratos ativos há mais de 6 meses

Identifica clientes com maior tempo de relacionamento ativo.
Decisão: `data\_cancelamento IS NULL` para garantir que apenas contratos realmente ativos aparecem. `CURRENT\_DATE - data\_inicio` retorna `integer` no PostgreSQL quando ambos são `date`.

\---

## Nível 3 - Análises analíticas

### Q7 - Top 3 vendedores por MRR em cada mês

Ranking mensal sem subqueries - usando `DENSE\_RANK() OVER(PARTITION BY mes ORDER BY mrr DESC)`.
Decisão: `DENSE\_RANK` em vez de `ROW\_NUMBER` para empatar vendedores com mesmo MRR na mesma posição.
Decisão: `DATE\_TRUNC('month', ...)` em vez de `DATE\_PART('month', ...)` para preservar o ano, bases com 18 meses teriam jan/2025 e jan/2026 agrupados incorretamente com DATE\_PART.

### Q8 - Taxa de conversão por canal com variação MoM

Funil de canal mês a mês com três CTEs: jornada do lead, cálculo da taxa e variação percentual.
Decisão: variação MoM calculada como percentual da taxa anterior (não variação absoluta), mais significativo para comparar períodos com volumes diferentes.
Decisão: `NULLIF(taxa\_pm, 0)` para evitar divisão por zero no primeiro mês de cada canal.
Decisão: oportunidades abertas filtradas com `NOT IN ('fechado\_ganho', 'fechado\_perdido')` para incluir todos os stages em aberto.

### Q9 - Vendedores abaixo da média do time

Calcula a média geral do time em CTE separada e compara individualmente via `CROSS JOIN`.
Decisão: `CROSS JOIN` entre a CTE do vendedor e a CTE da média geral, forma correta de comparar cada linha com um valor agregado único sem subquery no WHERE.

### Q10 - Análise de coorte de aquisição

Agrupa leads pelo mês de entrada e acompanha a jornada de cada coorte: leads → oportunidades → contratos → MRR médio.
Decisão: `LEFT JOIN` em toda a cadeia para garantir que coortes sem oportunidade ou contrato apareçam com zero, não sejam excluídas.

\---

## Nível 4 - Desafios AE

### Q11 - Funil de conversão completo

Constrói o funil completo em duas perspectivas:

**Por etapa** (taxa de cada etapa em relação à anterior):

```
Leads totais → Leads qualificados → Oportunidades abertas → Oportunidades ganhas → Contratos ativos → MRR total
```

**Topo de funil** (todas as taxas em relação ao total de leads):

```
Leads qualificados / total → Oportunidades / total → Contratos / total
```

Decisão: `UNION ALL` para retornar uma linha por etapa - formato mais adequado para consumo por dashboards e ferramentas de BI.
Decisão: três CTEs de agregação (`leads\_agg`, `oportunidades\_agg`, `contratos\_agg`) reutilizadas em múltiplas CTEs de cálculo via `CROSS JOIN`, evita reprocessamento das tabelas.

### Q12 - Detecção de anomalias de dados

Identifica dois tipos de inconsistência temporal:

**Em oportunidades:**

* `data\_entrada > data\_abertura`: lead entrou depois da oportunidade ser aberta
* `data\_abertura > data\_fechamento`: oportunidade fechou antes de ser aberta

**Em contratos:**

* `data\_fechamento > data\_inicio`: contrato iniciou antes da oportunidade fechar (impossível no fluxo real)

Decisão: duas CTEs separadas por fonte (`opp\_diag`, `ctt\_diag`) para manter rastreabilidade - a coluna `fonte` + `ID` permitem que o analista vá diretamente ao registro problemático no sistema de origem.
Decisão: `CASE WHEN` com descrições textuais do tipo de anomalia em vez de flags booleanas - mais informativo para quem vai investigar o dado.
Decisão: `WHERE motivo\_anomalia IS NOT NULL` em vez de listar todas as descrições no IN - mais robusto a mudanças nas descrições dos casos.

\---

## Observações técnicas

* `DISTINCT` mantido apenas em cenários onde JOINs com atividades poderiam multiplicar registros
* Múltiplas abordagens para o mesmo problema foram mantidas intencionalmente (ex: Q11 em linha e em coluna) para documentar diferentes formas de apresentar o mesmo dado
* `NULLIF` aplicado consistentemente em todos os denominadores de divisão

\---

## Tecnologias

* PostgreSQL
* SQL (CTEs, window functions, FILTER, UNION ALL, CROSS JOIN, CASE WHEN)
* Git / GitHub

