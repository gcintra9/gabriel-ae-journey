CREATE TABLE IF NOT EXISTS dw.dim_oportunidades
(
  id               NUMERIC (15)  PRIMARY KEY
, lead_id          NUMERIC (15)  REFERENCES dw.dim_leads(id)
, vendedor         VARCHAR (100) REFERENCES dw.dim_vendedor(vendedor)
, stage            VARCHAR (30)
, moeda            VARCHAR (5)
, motivo_perda     VARCHAR (100)
, concorrente      VARCHAR (80)
, proposta_enviada BOOLEAN
);