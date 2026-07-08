CREATE OR REPLACE PROCEDURE USP_DW_CARGA_FACT_LEADS()
LANGUAGE plpgsql
AS $$
BEGIN
 
-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------
 
CREATE TABLE IF NOT EXISTS dw.fact_LEADS
(
  id                  NUMERIC (15) PRIMARY KEY REFERENCES dw.dim_leads(id)
, data_entrada        DATE
, canal               VARCHAR (50)
, subcanal            VARCHAR (50)
, chave_canal         VARCHAR (103)
);
 
--------------------------------
-- LIMPA E POPULA A TABELA DO DW
--------------------------------
 
MERGE INTO dw.fact_LEADS AS tgt
USING tratamento.VW_F_LEADS AS src
ON (tgt.id = src.id)
 
WHEN MATCHED THEN
	UPDATE SET
		  data_entrada        = src.data_entrada
		  , canal               = src.canal
		  , subcanal            = src.subcanal
		  , chave_canal         = src.chave_canal
 
WHEN NOT MATCHED THEN
	INSERT (
		  id
		, data_entrada
		, canal
		, subcanal
		, chave_canal
	)
	VALUES (
		  src.id
		, src.data_entrada
		, src.canal
		, src.subcanal
		, src.chave_canal
	)
 
WHEN NOT MATCHED BY SOURCE THEN
	DELETE;
 
END;
$$;