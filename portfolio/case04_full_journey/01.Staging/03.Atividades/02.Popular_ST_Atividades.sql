TRUNCATE TABLE staging.ST_ATIVIDADES

INSERT INTO staging.ST_ATIVIDADES
(
	  id
	, oportunidade_id
	, tipo
	, data_atividade
	, hora_atividade
	, compareceu
	, duracao_min
	, canal_atividade
	, responsavel
)

SELECT
	  id
	, oportunidade_id
	, tipo
	, data_atividade
	, hora_atividade
	, compareceu
	, duracao_min
	, canal_atividade
	, responsavel
FROM public.atividades;