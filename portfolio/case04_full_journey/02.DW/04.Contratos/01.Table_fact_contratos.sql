CREATE TABLE IF NOT EXISTS dw.fact_contratos
(
  id                   NUMERIC (15) PRIMARY KEY NOT NULL
, oportunidade_id      NUMERIC (15) REFERENCES dw.dim_oportunidades(id)
, data_inicio          DATE 
, data_cancelamento    DATE 
, data_renovacao       DATE
, flag_anomalia_data   BOOLEAN 
, motivo_anomalia_data VARCHAR (100)
, plano                VARCHAR (50)
, periodicidade        VARCHAR (20)
, mrr                  NUMERIC (10,2) 
, desconto_perc        NUMERIC (6,2)
, mrr_bruto            NUMERIC (10,2)
, motivo_cancelamento  VARCHAR (100)
, nps_score            INTEGER
, escala_nps           VARCHAR (50)
, csm_responsavel      VARCHAR (100)
);