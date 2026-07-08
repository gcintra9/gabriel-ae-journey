CREATE VIEW tratamento.VW_F_CONTRATOS AS

	SELECT
		  id                                               AS id
		, oportunidade_id                                  AS oportunidade_id
		, data_inicio                                      AS data_inicio
		, data_cancelamento                                AS data_cancelamento
		, data_renovacao                                   AS data_renovacao
		, CASE
			WHEN data_renovacao < data_inicio 
				THEN TRUE
			WHEN data_cancelamento < data_inicio 
				THEN TRUE
			WHEN data_renovacao IS NOT NULL AND data_cancelamento IS NOT NULL 
				THEN TRUE
			ELSE     FALSE
		END                                                AS flag_anomalia_data
		, CASE
			WHEN data_renovacao < data_inicio 
				THEN 'Renovação anterior ao início'
			WHEN data_cancelamento < data_inicio 
				THEN 'Cancelamento anterior ao início'
			WHEN data_renovacao IS NOT NULL AND data_cancelamento IS NOT NULL 
				THEN 'Contrato com renovação e cancelamento simultâneos'
			ELSE     'Sem Flag'
		END                                                AS motivo_anomalia_data
		, CASE
			WHEN NULLIF(TRIM(plano),'') IS NULL
				THEN 'Não Informado'
			ELSE TRIM(plano)
		END                                                AS plano
		, TRIM(periodicidade)                              AS periodicidade
		, mrr                                              AS mrr
		, desconto_perc                                    AS desconto_perc
		, mrr_bruto                                        AS mrr_bruto
		, CASE
			WHEN data_cancelamento IS NOT NULL AND NULLIF(TRIM(motivo_cancelamento),'') IS NULL
				THEN 'Não Informado'
			WHEN data_cancelamento IS NULL AND NULLIF(TRIM(motivo_cancelamento),'') IS NULL
				THEN 'Cliente Ativo'
			ELSE TRIM(motivo_cancelamento)
			END                                            AS motivo_cancelamento
		, nps_score                                        AS nps_score
		, CASE
			WHEN nps_score IS NULL THEN 'Não Informado'
			WHEN nps_score > 10    THEN 'Score inválido'
			WHEN nps_score >= 9    THEN 'Promotor'
			WHEN nps_score >= 7    THEN 'Neutro'
			WHEN nps_score >= 0    THEN 'Detrator'
			ELSE                        'Não Informado'
		END                                                AS escala_nps
		, COALESCE(TRIM(csm_responsavel), 'Não Informado') AS csm_responsavel
	FROM staging.st_contratos;