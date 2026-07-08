CREATE VIEW tratamento.VW_D_PLANOS AS

	SELECT
		  COALESCE(TRIM(plano), 'Não Informado')         AS plano
		, COALESCE(TRIM(periodicidade), 'Não Informado') AS periodicidade
	FROM staging.st_planos;