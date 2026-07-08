TRUNCATE TABLE staging.ST_CONTRATOS

INSERT INTO staging.ST_CONTRATOS
(
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

SELECT
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
FROM public.contratos;