CREATE TABLE IF NOT EXISTS staging.ST_CUSTOS
(
    id         NUMERIC (15)
  , canal      VARCHAR (50)
  , subcanal   VARCHAR (50)
  , mes_ref    DATE
  , custo      NUMERIC (10,2)
  , impressoes INTEGER
  , cliques    INTEGER
  , moeda      VARCHAR (5)
);