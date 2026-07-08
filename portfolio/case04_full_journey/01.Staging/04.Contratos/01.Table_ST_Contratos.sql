CREATE TABLE IF NOT EXISTS staging.ST_CONTRATOS
(
  id                  NUMERIC (15) 
, oportunidade_id     NUMERIC (15) 
, data_inicio         DATE 
, data_cancelamento   DATE 
, data_renovacao      DATE 
, plano               VARCHAR (50)
, periodicidade       VARCHAR (20)
, mrr                 NUMERIC 
, desconto_perc       NUMERIC 
, mrr_bruto           NUMERIC 
, motivo_cancelamento VARCHAR (100)
, nps_score           INTEGER 
, csm_responsavel     VARCHAR (100)
);