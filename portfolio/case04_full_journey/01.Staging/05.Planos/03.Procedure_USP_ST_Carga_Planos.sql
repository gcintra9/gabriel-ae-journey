CREATE OR REPLACE PROCEDURE USP_ST_CARGA_PLANOS()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

CREATE TABLE IF NOT EXISTS staging.ST_PLANOS
(
  plano         VARCHAR (50)
, periodicidade VARCHAR (20)
);

---------------------
-- LIMPA A STAGE ÁREA
---------------------

TRUNCATE TABLE staging.ST_PLANOS;

----------------------
-- POPULA A STAGE ÁREA
----------------------

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


END;
$$;