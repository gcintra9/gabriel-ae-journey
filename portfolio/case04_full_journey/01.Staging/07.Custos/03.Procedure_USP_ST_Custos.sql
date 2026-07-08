CREATE OR REPLACE PROCEDURE USP_ST_CARGA_CUSTOS()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

CREATE TABLE IF NOT EXISTS staging.ST_CUSTOS
(
    id         NUMERIC (15)
  , canal      VARCHAR (50)
  , subcanal   VARCHAR (50)
  , mes_ref    DATE
  , custo      NUMERIC (10,2)
  , impressoes INTEGER
  , cliques    INTEGER
  , moeda      VARCHAR (5)
);

------------------------------
-- LIMPA E POPULA A STAGE ÁREA
------------------------------

MERGE INTO staging.ST_CUSTOS AS tgt
USING public.custos_canal AS src
ON (tgt.id = src.id)

WHEN MATCHED THEN
	UPDATE SET
	  canal      = src.canal 
	, subcanal   = src.subcanal 
	, mes_ref    = src.mes_ref 
	, custo      = src.custo 
	, impressoes = src.impressoes 
	, cliques    = src.cliques 
	, moeda      = src.moeda 

WHEN NOT MATCHED THEN
	INSERT (
		  id
		, canal
		, subcanal
		, mes_ref
		, custo
		, impressoes
		, cliques
		, moeda
	)
	VALUES (
		  src.id
		, src.canal
		, src.subcanal
		, src.mes_ref
		, src.custo
		, src.impressoes
		, src.cliques
		, src.moeda
	)

WHEN NOT MATCHED BY SOURCE THEN
	DELETE;

END;
$$;