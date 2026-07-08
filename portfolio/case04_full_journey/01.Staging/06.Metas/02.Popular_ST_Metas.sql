TRUNCATE TABLE staging.ST_METAS

INSERT INTO staging.ST_METAS
(
	  id
	, vendedor
	, mes_ref
	, meta_oportunidades
	, meta_mrr
	, meta_win_rate
)

SELECT
	  id
	, vendedor
	, mes_ref
	, meta_oportunidades
	, meta_mrr
	, meta_win_rate
FROM public.meta_vendedor;