TRUNCATE TABLE staging.ST_CUSTOS

INSERT INTO staging.ST_CUSTOS
(
	  id
	, canal
	, subcanal
	, mes_ref
	, custo
	, impressoes
	, cliques
	, moeda
)
SELECT
	  id
	, canal
	, subcanal
	, mes_ref
	, custo
	, impressoes
	, cliques
	, moeda
FROM
	public.custos_canal;