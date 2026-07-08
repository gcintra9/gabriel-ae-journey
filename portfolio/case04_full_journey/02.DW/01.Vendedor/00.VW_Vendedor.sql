CREATE VIEW tratamento.VW_D_VENDEDOR AS

	SELECT
		  COALESCE(INITCAP(TRIM(vendedor)), 'Não Informado') AS vendedor
		, COALESCE(INITCAP(TRIM(squad)), 'Não Informado')    AS squad
	FROM staging.st_vendedor;