TRUNCATE TABLE staging.ST_OPORTUNIDADES

INSERT INTO staging.ST_OPORTUNIDADES
(
  id
, lead_id
, vendedor
, data_abertura
, data_fechamento
, stage
, valor_mrr
, valor_anual
, moeda
, motivo_perda
, concorrente
, numero_reunioes
, proposta_enviada
)

SELECT
	  id
	, lead_id
	, vendedor
	, data_abertura
	, data_fechamento
	, stage
	, valor_mrr
	, valor_anual
	, moeda
	, motivo_perda
	, concorrente
	, numero_reunioes
	, proposta_enviada
FROM public.oportunidades;