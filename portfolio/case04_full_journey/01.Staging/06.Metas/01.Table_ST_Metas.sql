CREATE TABLE IF NOT EXISTS staging.ST_METAS(
	  id NUMERIC (15)
	, vendedor VARCHAR (100)
	, mes_ref DATE
	, meta_oportunidades INTEGER
	, meta_mrr NUMERIC (10,2)
	, meta_win_rate NUMERIC (5,2)
)