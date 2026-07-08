CREATE OR REPLACE PROCEDURE USP_DW_CARGA_CUSTOS()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

CREATE TABLE IF NOT EXISTS dw.fact_CUSTOS
(
    id          NUMERIC (15) PRIMARY KEY NOT NULL
  , canal       VARCHAR (50)
  , subcanal    VARCHAR (50)
  , chave_canal VARCHAR (103)
  , mes_ref     DATE
  , custo       NUMERIC (10,2)
  , impressoes  INTEGER
  , cliques     INTEGER
  , moeda       VARCHAR (5)
);

------------------------------
-- LIMPA E POPULA A STAGE ÁREA
------------------------------

MERGE INTO dw.fact_custos    AS tgt
USING tratamento.VW_F_CUSTOS AS src
ON (tgt.id = src.id)

WHEN MATCHED THEN
	UPDATE SET
    canal       = src.canal
  , subcanal    = src.subcanal
  , chave_canal = src.chave_canal
  , mes_ref     = src.mes_ref
  , custo       = src.custo
  , impressoes  = src.impressoes
  , cliques     = src.cliques
  , moeda       = src.moeda

WHEN NOT MATCHED THEN
	INSERT (
		  id
	  	, canal
		, subcanal
		, chave_canal
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
		, src.chave_canal
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