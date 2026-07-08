CREATE TABLE IF NOT EXISTS dw.fact_CUSTOS
(
    id         NUMERIC (15) PRIMARY KEY NOT NULL
  , canal      VARCHAR (50)
  , subcanal   VARCHAR (50)
  , mes_ref    DATE
  , custo      NUMERIC (10,2)
  , impressoes INTEGER
  , cliques    INTEGER
  , moeda      VARCHAR (5)
);