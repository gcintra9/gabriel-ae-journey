CREATE TABLE IF NOT EXISTS staging.ST_LEADS
(
  id           NUMERIC (15)
, nome         VARCHAR (100)
, email        VARCHAR (80)
, telefone     VARCHAR (30)
, empresa      VARCHAR (100)
, cargo        VARCHAR (80)
, segmento     VARCHAR (50)
, porte        VARCHAR (20)
, canal        VARCHAR (50)
, subcanal     VARCHAR (50)
, data_entrada DATE
, status       VARCHAR (30)
, motivo_perda VARCHAR (100)
, lead_score   INTEGER
, cidade       VARCHAR (60)
, estado       CHAR    (2)
, pais         VARCHAR (30)
);