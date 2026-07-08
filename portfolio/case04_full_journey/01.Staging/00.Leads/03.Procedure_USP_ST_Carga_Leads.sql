CREATE OR REPLACE PROCEDURE USP_ST_CARGA_LEADS()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

CREATE TABLE IF NOT EXISTS staging.ST_LEADS
(
  id           NUMERIC (15)
, nome         VARCHAR (100)
, email        VARCHAR (80)
, telefone     VARCHAR (30)
, empresa      VARCHAR (100)
, cargo        VARCHAR (80)
, segmento     VARCHAR (50)
, porte        VARCHAR (20)
, canal        VARCHAR (50)
, subcanal     VARCHAR (50)
, data_entrada DATE
, status       VARCHAR (30)
, motivo_perda VARCHAR (100)
, lead_score   INTEGER
, cidade       VARCHAR (60)
, estado       CHAR    (2)
, pais         VARCHAR (30)
);

---------------------
-- LIMPA A STAGE ÁREA
---------------------

TRUNCATE TABLE staging.ST_LEADS;

----------------------
-- POPULA A STAGE ÁREA
----------------------

INSERT INTO staging.ST_LEADS
(
  id
, nome
, email
, telefone
, empresa
, cargo
, segmento
, porte
, canal
, subcanal
, data_entrada
, status
, motivo_perda
, lead_score
, cidade
, estado
, pais
)
SELECT
	  id
	, nome
	, email
	, telefone
	, empresa
	, cargo
	, segmento
	, porte
	, canal
	, subcanal
	, data_entrada
	, status
	, motivo_perda
	, lead_score
	, cidade
	, estado
	, pais
FROM
	public.leads;
END;
$$;