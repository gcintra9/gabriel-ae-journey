CREATE TABLE IF NOT EXISTS dw.fact_metas(
    id NUMERIC (15) PRIMARY KEY NOT NULL
  , vendedor VARCHAR (100) REFERENCES dw.dim_vendedor(vendedor)
  , mes_ref DATE
  , meta_oportunidades INTEGER
  , meta_mrr NUMERIC (10,2)
  , meta_win_rate NUMERIC (5,2)
);