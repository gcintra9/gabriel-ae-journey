TRUNCATE TABLE staging.ST_PLANOS

INSERT INTO staging.ST_PLANOS
(
  plano
, periodicidade
)

SELECT DISTINCT
  plano
, periodicidade
FROM public.contratos
WHERE plano IS NOT NULL;