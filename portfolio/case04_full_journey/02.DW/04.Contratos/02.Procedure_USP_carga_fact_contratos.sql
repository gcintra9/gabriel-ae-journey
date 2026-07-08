CREATE OR REPLACE PROCEDURE USP_DW_CARGA_CONTRATOS()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

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

------------------------------
-- LIMPA E POPULA A STAGE ÁREA
------------------------------

MERGE INTO dw.fact_contratos AS tgt
USING tratamento.VW_F_CONTRATOS AS src
ON (tgt.id = src.id)

WHEN MATCHED THEN
	UPDATE SET
	  oportunidade_id      = src.oportunidade_id 
	, data_inicio          = src.data_inicio 
	, data_cancelamento    = src.data_cancelamento 
	, data_renovacao       = src.data_renovacao
	, motivo_anomalia_data = src.motivo_anomalia_data
	, flag_anomalia_data   = src.flag_anomalia_data
	, plano                = src.plano
	, periodicidade        = src.periodicidade
	, mrr                  = src.mrr
	, desconto_perc        = src.desconto_perc
	, mrr_bruto            = src.mrr_bruto
	, motivo_cancelamento  = src.motivo_cancelamento
	, nps_score            = src.nps_score
	, escala_nps           = src.escala_nps
	, csm_responsavel      = src.csm_responsavel

WHEN NOT MATCHED THEN
	INSERT (
		  id
		, oportunidade_id
		, data_inicio
		, data_cancelamento
		, data_renovacao
		, motivo_anomalia_data
		, flag_anomalia_data
		, plano
		, periodicidade
		, mrr
		, desconto_perc
		, mrr_bruto
		, motivo_cancelamento
		, nps_score
		, escala_nps
		, csm_responsavel
	)
	VALUES (
		  src.id
		, src.oportunidade_id
		, src.data_inicio
		, src.data_cancelamento
		, src.data_renovacao
		, src.motivo_anomalia_data
		, src.flag_anomalia_data
		, src.plano
		, src.periodicidade
		, src.mrr
		, src.desconto_perc
		, src.mrr_bruto
		, src.motivo_cancelamento
		, src.nps_score
		, src.escala_nps
		, src.csm_responsavel
	)

WHEN NOT MATCHED BY SOURCE THEN
	DELETE;

END;
$$;