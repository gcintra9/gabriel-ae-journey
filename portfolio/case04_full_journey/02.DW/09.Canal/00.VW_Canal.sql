CREATE OR REPLACE VIEW tratamento.VW_D_CANAL AS
WITH leads_canal AS
(
    SELECT
        TRIM(canal) AS canal,
        CASE
            WHEN NULLIF(TRIM(subcanal), '') IS NULL
                 AND TRIM(canal) = 'indicacao'
                THEN 'Sem Subcanal'
            WHEN NULLIF(TRIM(subcanal), '') IS NULL
                THEN 'Não Informado'
            ELSE TRIM(subcanal)
        END AS subcanal_tratado
    FROM staging.st_leads
    WHERE canal IS NOT NULL
),

custos_canal AS
(
    SELECT
        TRIM(canal) AS canal,
        CASE
            WHEN NULLIF(TRIM(subcanal), '') IS NULL
                THEN 'Sem Subcanal'
            ELSE TRIM(subcanal)
        END AS subcanal_tratado
    FROM staging.st_custos
    WHERE canal IS NOT NULL
),

tratado AS
(
    SELECT *
    FROM leads_canal

    UNION

    SELECT *
    FROM custos_canal
)

SELECT DISTINCT
    canal || '|' || subcanal_tratado AS chave_canal,
    canal,
    subcanal_tratado AS subcanal
FROM tratado;