CREATE VIEW tratamento.VW_D_OPORTUNIDADE AS
	SELECT
		  id                                                 AS id
		, lead_id                                            AS lead_id
		, COALESCE(INITCAP(TRIM(vendedor)), 'Não Informado') AS vendedor
		, TRIM(stage)                                        AS stage
		, UPPER(TRIM(moeda))                                 AS moeda
		, CASE
			WHEN stage = 'fechado_perdido' AND NULLIF(TRIM(motivo_perda),'') IS NULL
				THEN 'Não Informado'
			WHEN stage <> 'fechado_perdido'
				THEN 'Sem Perda'
			ELSE INITCAP(TRIM(motivo_perda))
			END                                              AS motivo_perda
		, CASE
			WHEN stage = 'fechado_perdido' AND NULLIF(TRIM(concorrente),'') IS NULL
				THEN 'Não Informado'
			WHEN stage = 'fechado_perdido'
				THEN INITCAP(TRIM(concorrente))
			ELSE 'Sem Concorrente'
			END                                              AS concorrente
		, proposta_enviada                                   AS proposta_enviada
	FROM staging.st_oportunidades;