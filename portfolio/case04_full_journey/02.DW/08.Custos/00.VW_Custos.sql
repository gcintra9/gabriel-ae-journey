CREATE OR REPLACE VIEW tratamento.VW_F_CUSTOS AS

WITH custos_tratados AS
(

	SELECT
		  id                             AS id
		, CASE
			WHEN NULLIF(TRIM(canal),'') IS NULL
				THEN 'Não Informado'
			ELSE TRIM(canal) 
		END                              AS canal
		, CASE
			WHEN NULLIF(TRIM(subcanal),'') IS NULL AND TRIM(CANAL) = 'indicacao'
				THEN 'Sem Subcanal'
		    WHEN NULLIF(TRIM(subcanal),'') IS NULL
		    	THEN 'Não Informado'
			ELSE TRIM(subcanal)
		END                              AS subcanal
		, DATE_TRUNC('month', mes_ref)   AS mes_ref
		, custo                          AS custo
		, impressoes                     AS impressoes
		, cliques                        AS cliques
		, UPPER(TRIM(moeda))             AS moeda
	FROM staging.st_custos
)
SELECT
	id
	, canal
	, subcanal
	, canal || '|' || subcanal AS chave_canal
	, mes_ref
	, custo
	, impressoes
	, cliques
	, moeda
FROM custos_tratados;