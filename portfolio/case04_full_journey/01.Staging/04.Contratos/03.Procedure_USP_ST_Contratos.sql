CREATE OR REPLACE PROCEDURE USP_ST_CARGA_CONTRATOS()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

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

------------------------------
-- LIMPA E POPULA A STAGE ÁREA
------------------------------

MERGE INTO staging.ST_CONTRATOS AS tgt
USING public.contratos AS src
ON (tgt.id = src.id)

WHEN MATCHED THEN
	UPDATE SET
		oportunidade_id     = src.oportunidade_id
	, data_inicio         = src.data_inicio
	, data_cancelamento   = src.data_cancelamento
	, data_renovacao      = src.data_renovacao
	, plano               = src.plano
	, periodicidade       = src.periodicidade
	, mrr                 = src.mrr
	, desconto_perc       = src.desconto_perc
	, mrr_bruto           = src.mrr_bruto
	, motivo_cancelamento = src.motivo_cancelamento
	, nps_score           = src.nps_score
	, csm_responsavel     = src.csm_responsavel

WHEN NOT MATCHED THEN
	INSERT (
		  id
		, oportunidade_id
		, data_inicio
		, data_cancelamento
		, data_renovacao
		, plano
		, periodicidade
		, mrr
		, desconto_perc
		, mrr_bruto
		, motivo_cancelamento
		, nps_score
		, csm_responsavel
	)
	VALUES (
		src.id
	, src.oportunidade_id
	, src.data_inicio
	, src.data_cancelamento
	, src.data_renovacao
	, src.plano
	, src.periodicidade
	, src.mrr
	, src.desconto_perc
	, src.mrr_bruto
	, src.motivo_cancelamento
	, src.nps_score
	, src.csm_responsavel
	)

WHEN NOT MATCHED BY SOURCE THEN
	DELETE;

END;
$$;