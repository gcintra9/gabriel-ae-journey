# Gabriel Cintra - Analytics Engineer Journey

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-336791?style=flat&logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.x-3776AB?style=flat&logo=python&logoColor=white)
![dbt](https://img.shields.io/badge/dbt-Core-FF694B?style=flat&logo=dbt&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-DAX-F2C811?style=flat&logo=powerbi&logoColor=black)
![BigQuery](https://img.shields.io/badge/BigQuery-GCP-4285F4?style=flat&logo=googlecloud&logoColor=white)
![Git](https://img.shields.io/badge/Git-GitHub-181717?style=flat&logo=github&logoColor=white)

Repositório de estudos e projetos práticos na jornada de transição para **Analytics Engineering**.
Foco em SQL avançado, modelagem dimensional, pipelines com dbt, Python para dados e BigQuery.

\---

## Sobre

Analista de Dados Sênior com experiência em **BI, RevOps e modelagem de Data Warehouse** (star/snowflake),
em transição para Analytics Engineer. Este repositório documenta o processo de aprendizado com projetos
que simulam cenários reais de negócio — desde queries analíticas até pipelines completos com SQL + Power BI,
e futuramente dbt + BigQuery.

\---

## Estrutura

```
gabriel-ae-journey/
├── sql/          → Exercícios, cases analíticos e queries de negócio (PostgreSQL)
├── python/       → Scripts de ingestão, transformação e automação de dados
├── dbt/          → Modelos analíticos, testes, documentação e BUSINESS\_RULES.md
└── portfolio/    → Projetos completos com SQL + Power BI
```

\---

## Cases SQL

|#|Case|Técnicas|Status|
|-|-|-|-|
|01|[Funil de Vendas e Receita](sql/case01_funil_vendas/case01_funil.sql)|CTEs, DENSE\_RANK, LAG, AVG OVER, NOT EXISTS|✅ Concluído|
|02|[Otimização de Query](sql/case02_otimizacao_query/case02_otimizacao.sql)|EXPLAIN ANALYZE, índices compostos, MERGE vs subquery|✅ Concluído|
|03|[Performance Comercial](sql/case03_performance_comercial/case03_performance.sql)|Funil, coorte, UNION ALL, CROSS JOIN, anomalias (12 questões)|✅ Concluído|

\---

## Cases de Portfólio

|#|Projeto|Domínio|Stack|Status|
|-|-|-|-|-|
|**04**|[Full Journey — RevOps B2B](portfolio/case04_full_journey/README.md)|RevOps B2B (Lead → Contrato)|PostgreSQL (star schema, PL/pgSQL) + Power BI (DAX avançado)|✅ Concluído|
|P1|Análise Comercial — Olist|E-commerce|SQL + Power BI + dbt|🔄 Em desenvolvimento|
|P2|Análise Financeira — Bank Marketing|Financeiro|SQL + Power BI|🔄 Em desenvolvimento|
|P3|People Analytics — IBM HR|RH / Turnover|SQL + Power BI|🔄 Em desenvolvimento|
|P4|NYC Yellow Cabs|Transportes|Power BI + Fabric|🔄 Evoluindo|

**Destaque — Case 04 (Full Journey):** pipeline completo de dados de RevOps B2B, do lead até o contrato ativo — staging → tratamento → star schema (Kimball) → dashboard executivo com 3 páginas por persona (Diretor Comercial, CEO, Head de Marketing), com insights dinâmicos via DAX. [Dashboard publicado no Power BI Service](portfolio/case04_full_journey/README.md).

\---

## Stack técnico

**Dados & Transformação**

* SQL avançado - CTEs, window functions, otimização de queries, MERGE/upsert
* Modelagem dimensional - star schema (Kimball), refatoração fato/dimensão, flags de qualidade
* dbt Core - modelagem dimensional, testes, documentação, BUSINESS\_RULES.md *(em formação)*
* Python - pandas, sqlalchemy, requests, ingestão via API *(em formação)*

**Plataformas & Cloud**

* PostgreSQL (local) · BigQuery / GCP *(em formação)*
* Microsoft Fabric · Apache HOP · Microsoft Power BI (DAX avançado)
* Git · GitHub

**Negócio**

* RevOps · Funil de vendas · MRR · Churn · Modelagem DW (star/snowflake) · Storytelling de dashboard por persona

\---

## Contato

[![LinkedIn](https://img.shields.io/badge/LinkedIn-gabriel--cintra--power--bi-0A66C2?style=flat&logo=linkedin&logoColor=white)](https://linkedin.com/in/gabriel-cintra-power-bi)

