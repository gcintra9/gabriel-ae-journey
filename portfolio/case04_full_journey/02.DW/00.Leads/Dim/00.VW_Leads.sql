CREATE OR REPLACE VIEW tratamento.VW_D_LEADS AS

SELECT
	id
	, INITCAP(TRIM(nome))                    AS nome
	, CASE
		WHEN NULLIF(TRIM(email),'') IS NULL
			THEN 'Não Informado'
		WHEN email NOT LIKE '%@%.%'
			THEN 'E-mail Inválido'
		ELSE LOWER(TRIM(email))
	END                                      AS email
	, CASE
		WHEN NULLIF(TRIM(telefone), '') IS NULL
			THEN 'Não Informado'

		WHEN LENGTH(REPLACE(TRIM(telefone), '-', '')) = 11
			THEN '+55 (' || LEFT(REPLACE(TRIM(telefone), '-', ''), 2) || ') ' || SUBSTRING(REPLACE(TRIM(telefone), '-', '') FROM 3)

		WHEN LENGTH(REPLACE(TRIM(telefone), '-', '')) = 12
			THEN '+55 (' || LEFT(REPLACE(TRIM(telefone), '-', ''), 2) || ')' || SUBSTRING(REPLACE(TRIM(telefone), '-', '') FROM 3)

		WHEN LENGTH(REPLACE(TRIM(telefone), '-', '')) = 14
			THEN '+55 ' || REPLACE(TRIM(telefone), '-', '')

		WHEN LENGTH(REPLACE(TRIM(telefone), '-', '')) = 16
			THEN LEFT(REPLACE(TRIM(telefone), '-', ''), 4) || '(' || LEFT(SUBSTRING(REPLACE(TRIM(telefone), '-', '') FROM 5),2) || ')' || SUBSTRING(REPLACE(TRIM(telefone), '-', '') FROM 7) 

		ELSE 'Formato Inválido'

		END                                  AS telefone
	, INITCAP(TRIM(empresa))                 AS empresa
	, INITCAP(TRIM(cargo))                   AS cargo
	, INITCAP(TRIM(segmento))                AS segmento
	, status                                 AS status
	, CASE
		WHEN status = 'desqualificado' AND NULLIF(TRIM(motivo_perda),'') IS NULL
			THEN 'Não Informado'
		WHEN status = 'desqualificado'
			THEN INITCAP(TRIM(motivo_perda))
		WHEN status <> 'desqualificado'
			THEN 'Sem Perda'
		END                                 AS motivo_perda
	, lead_score                            AS lead_score
	, CASE
	    WHEN lead_score >= 80 THEN 'Alto'
	    WHEN lead_score >= 50 THEN 'Médio'
	    WHEN lead_score >= 20 THEN 'Baixo'
	    ELSE 'Sem Score'
	  END                                    AS classificacao_score
	, INITCAP(TRIM(porte))                   AS porte
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
	, INITCAP(TRIM(cidade))                  AS cidade
	, UPPER(TRIM(estado))                    AS estado
	, INITCAP(TRIM(pais))                    AS pais
FROM staging.st_leads;