CREATE TABLE IF NOT EXISTS dw.fact_LEADS
(
  id                  NUMERIC (15) PRIMARY KEY REFERENCES dw.dim_leads(id)
, data_entrada        DATE
, canal               VARCHAR (50)
, subcanal            VARCHAR (50)
, chave_canal         VARCHAR (103)
);