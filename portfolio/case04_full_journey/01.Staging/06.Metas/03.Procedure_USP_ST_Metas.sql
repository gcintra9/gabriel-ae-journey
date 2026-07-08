CREATE OR REPLACE PROCEDURE USP_ST_CARGA_METAS()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

CREATE TABLE IF NOT EXISTS staging.ST_METAS(
	  id NUMERIC (15)
	, vendedor VARCHAR (100)
	, mes_ref DATE
	, meta_oportunidades INTEGER
	, meta_mrr NUMERIC (10,2)
	, meta_win_rate NUMERIC (5,2)
);

------------------------------
-- LIMPA E POPULA A STAGE ÁREA
------------------------------

MERGE INTO staging.ST_METAS AS tgt
USING public.metas_vendedor AS src
ON (tgt.id = src.id)

WHEN MATCHED THEN
	UPDATE SET
	  vendedor = src.vendedor
	, mes_ref = src.mes_ref
	, meta_oportunidades = src.meta_oportunidades
	, meta_mrr = src.meta_mrr
	, meta_win_rate = src.meta_win_rate

WHEN NOT MATCHED THEN
	INSERT (
	  id
	, vendedor
	, mes_ref
	, meta_oportunidades
	, meta_mrr
	, meta_win_rate
	)

	VALUES (
		src.id
	, src.vendedor
	, src.mes_ref
	, src.meta_oportunidades
	, src.meta_mrr
	, src.meta_win_rate
	)

WHEN NOT MATCHED BY SOURCE THEN
	DELETE;

END;
$$;