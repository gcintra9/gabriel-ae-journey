CREATE TABLE IF NOT EXISTS dw.dim_LEADS
(
  id                  NUMERIC (15) PRIMARY KEY NOT NULL
, nome                VARCHAR (100)
, email               VARCHAR (80)
, telefone            VARCHAR (30)
, empresa             VARCHAR (100)
, cargo               VARCHAR (80)
, segmento            VARCHAR (50)
, status              VARCHAR (30)
, motivo_perda        VARCHAR (100)
, lead_score          INTEGER
, classificacao_score VARCHAR (20)
, porte               VARCHAR (20)
, cidade              VARCHAR (60)
, estado              CHAR    (2)
, pais                VARCHAR (30)
);