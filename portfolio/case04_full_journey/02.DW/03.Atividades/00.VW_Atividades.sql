CREATE VIEW tratamento.VW_F_ATIVIDADES AS

	SELECT	
		  id                                                    AS id
		, oportunidade_id                                       AS oportunidade_id
		, TRIM(tipo)                                            AS tipo
		, COALESCE(INITCAP(TRIM(responsavel)), 'Não Informado') AS responsavel
		, data_atividade                                        AS data_atividade
		, hora_atividade                                        AS hora_atividade
		, compareceu                                            AS compareceu
		, duracao_min                                           AS duracao_min
		, CASE
			WHEN compareceu = TRUE AND duracao_min IS NULL
				THEN 'Não Informado'
			WHEN duracao_min >= 90
				THEN 'Muito Longa'
			WHEN duracao_min >= 60
				THEN 'Longa'
			WHEN duracao_min >= 30
				THEN 'Normal'
			WHEN duracao_min >=  0
				THEN 'Curta'
			ELSE 'Não Compareceu'
			END                                                 AS classificacao_duracao
		, TRIM(canal_atividade)                                 AS canal_atividade
	FROM staging.st_atividades;