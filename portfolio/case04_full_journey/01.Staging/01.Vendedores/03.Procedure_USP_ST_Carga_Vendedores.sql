CREATE OR REPLACE PROCEDURE USP_ST_CARGA_VENDEDORES()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

CREATE TABLE IF NOT EXISTS staging.ST_VENDEDOR
(
  vendedor VARCHAR (100)
, squad    VARCHAR (50)
);


---------------------
-- LIMPA A STAGE ÁREA
---------------------

TRUNCATE TABLE staging.ST_VENDEDOR;

----------------------
-- POPULA A STAGE ÁREA
----------------------

INSERT INTO staging.ST_VENDEDOR
(
  vendedor
, squad
)
SELECT DISTINCT
	  vendedor
	, squad
FROM
	public.oportunidades
WHERE vendedor IS NOT NULL;

END;
$$;