CREATE OR REPLACE VIEW tratamento.VW_F_LEADS AS

WITH leads_tratado AS
(
	SELECT
		  id                                     AS id
		, data_entrada                           AS data_entrada
		, CASE
			WHEN NULLIF(TRIM(canal),'') IS NULL
				THEN 'Não Informado'
			ELSE TRIM(canal) 
		END                                      AS canal
		, CASE
			WHEN NULLIF(TRIM(subcanal),'') IS NULL AND TRIM(CANAL) = 'indicacao'
				THEN 'Sem Subcanal'
		    WHEN NULLIF(TRIM(subcanal),'') IS NULL
		    	THEN 'Não Informado'
			ELSE TRIM(subcanal)
		END                                      AS subcanal
	FROM staging.st_leads
)

SELECT
	  id                                          AS id
    , data_entrada                                AS data_entrada 
    , canal                                       AS canal
    , subcanal                                    AS subcanal
    , canal || '|' || subcanal                    AS chave_canal
FROM leads_tratado;