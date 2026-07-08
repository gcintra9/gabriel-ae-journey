CREATE OR REPLACE VIEW tratamento.VW_D_CALENDARIO AS

WITH data_ini AS
(
  SELECT
    MIN(data_entrada) AS data_min
  FROM staging.st_leads
),

data_fim AS (
  SELECT
    MAX(GREATEST(data_inicio, data_cancelamento, data_renovacao)) AS data_max
  FROM staging.st_contratos
),

ranges_def AS (
  SELECT
        a.data_min                                                                 AS data_min
      , EXTRACT(YEAR FROM a.data_min)                                              AS ano_min
      , b.data_max                                                                 AS data_max
      , EXTRACT(YEAR FROM b.data_max)                                              AS ano_max
      , DATE_TRUNC('year', data_min)::date                                         AS range_start
      , (DATE_TRUNC('year', data_max)+ INTERVAL '1 year' - INTERVAL '1 day')::date AS range_end
    FROM data_ini a
    CROSS JOIN data_fim b
),

dias_totais AS (
  SELECT
      range_start                   AS range_start
    , range_end                     AS range_end
    , (range_end - range_start) + 1 AS qtd_dias
  FROM ranges_def
),

calendario_bruto AS (

  SELECT
      gs::date            AS data
  FROM dias_totais
  , generate_series(
        range_start
      , range_end
      , INTERVAL '1 day'
  )                       AS gs
)

SELECT
    data                                                                 AS data
  , EXTRACT(DAY FROM data)                                               AS dia
  , EXTRACT(MONTH FROM data)                                             AS mes
  , EXTRACT(YEAR FROM data)                                              AS ano
  , TO_CHAR(data, 'month')                                               AS nome_mes
  , EXTRACT(WEEK FROM data)                                              AS semana
  , EXTRACT(ISODOW FROM data)                                            AS dia_semana
  , TO_CHAR(data, 'day')                                                 AS nome_dia
  , EXTRACT(DOY FROM data)                                               AS dia_ano
  , DATE_TRUNC('month', data)::date                                      AS inicio_mes
  , (DATE_TRUNC('month', data)
        + INTERVAL '1 month'
        - INTERVAL '1 day')::date                                        AS fim_mes
  , DATE_TRUNC('quarter', data)::date                                    AS inicio_trimestre
  , CASE
      WHEN EXTRACT(MONTH FROM data) > 9 THEN 4
      WHEN EXTRACT(MONTH FROM data) > 6 THEN 3
      WHEN EXTRACT(MONTH FROM data) > 3 THEN 2
                                        ELSE 1
    END                                                                  AS trimestre_num
  , DATE_TRUNC('year', data)::date                                       AS inicio_ano
  , TO_CHAR(data, 'Mon/YYYY')                                            AS mes_ano
  , (EXTRACT(YEAR FROM data)::int * 100 + EXTRACT(MONTH FROM data)::int) AS mes_ano_ordem
FROM calendario_bruto;