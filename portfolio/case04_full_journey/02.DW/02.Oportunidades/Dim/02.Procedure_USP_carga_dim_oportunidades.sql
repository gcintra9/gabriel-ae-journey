CREATE OR REPLACE PROCEDURE USP_DW_CARGA_DIM_OPORTUNIDADE()
LANGUAGE plpgsql
AS $$
BEGIN
-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------
CREATE TABLE IF NOT EXISTS dw.dim_oportunidades
(
  id               NUMERIC (15)  PRIMARY KEY
, lead_id          NUMERIC (15)  REFERENCES dw.dim_leads(id)
, vendedor         VARCHAR (100) REFERENCES dw.dim_vendedor(vendedor)
, stage            VARCHAR (30)
, moeda            VARCHAR (5)
, motivo_perda     VARCHAR (100)
, concorrente      VARCHAR (80)
, proposta_enviada BOOLEAN
);
------------------------------
-- LIMPA E POPULA A TABELA DO DW
------------------------------
MERGE INTO dw.dim_oportunidades     AS tgt
USING tratamento.VW_D_OPORTUNIDADE AS src
ON (tgt.id = src.id)

WHEN MATCHED THEN
	UPDATE SET
	  lead_id          = src.lead_id
	, vendedor         = src.vendedor
	, stage            = src.stage
	, moeda            = src.moeda
	, motivo_perda     = src.motivo_perda
	, concorrente      = src.concorrente
	, proposta_enviada = src.proposta_enviada

WHEN NOT MATCHED THEN
	INSERT (
		  id
		, lead_id
		, vendedor
		, stage
		, moeda
		, motivo_perda
		, concorrente
		, proposta_enviada
	)

	VALUES (
	  src.id
	, src.lead_id
	, src.vendedor
	, src.stage
	, src.moeda
	, src.motivo_perda
	, src.concorrente
	, src.proposta_enviada
	)

WHEN NOT MATCHED BY SOURCE THEN
	DELETE;
END;
$$;