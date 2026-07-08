CREATE VIEW tratamento.VW_F_METAS AS

	SELECT
	  id                           AS id
	, INITCAP(TRIM(vendedor))      AS vendedor
	, DATE_TRUNC('month', mes_ref) AS mes_ref
	, meta_oportunidades           AS meta_oportunidades
	, meta_mrr                     AS meta_mrr
	, meta_win_rate                AS meta_win_rate

	FROM staging.st_metas;