CREATE OR REPLACE PROCEDURE USP_DW_CARGA_VENDEDORES()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

CREATE TABLE IF NOT EXISTS dw.dim_vendedor
(
  vendedor VARCHAR (100) PRIMARY KEY NOT NULL
, squad    VARCHAR (50)
);

-----------------------------------
-- MERGE (UPSERT + DELETE ÓRFÃOS)
-----------------------------------

MERGE INTO dw.dim_vendedor AS tgt
USING (
	SELECT DISTINCT vendedor, squad
	FROM tratamento.VW_D_VENDEDOR
	WHERE vendedor IS NOT NULL
) AS src
ON (tgt.vendedor = src.vendedor)

WHEN MATCHED THEN
	UPDATE SET squad = src.squad

WHEN NOT MATCHED THEN
	INSERT (vendedor, squad)
	VALUES (src.vendedor, src.squad)

WHEN NOT MATCHED BY SOURCE THEN
	DELETE;

END;
$$;