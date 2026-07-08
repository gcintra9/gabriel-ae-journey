CREATE OR REPLACE PROCEDURE USP_ST_CARGA_OPORTUNIDADES()
LANGUAGE plpgsql

AS $$
BEGIN


-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

CREATE TABLE IF NOT EXISTS staging.ST_OPORTUNIDADES
(
  id	           NUMERIC (15)	
, lead_id	       NUMERIC (15)	
, vendedor	       VARCHAR (100)
, data_abertura	   DATE	
, data_fechamento  DATE	
, stage	           VARCHAR (30)
, valor_mrr	       NUMERIC (30)
, valor_anual	   NUMERIC (30)
, moeda	           VARCHAR (5)
, motivo_perda	   VARCHAR (100)
, concorrente	   VARCHAR (80)
, numero_reunioes  INTEGER	
, proposta_enviada BOOLEAN
);

------------------------------
-- LIMPA E POPULA A STAGE ÁREA
------------------------------

MERGE INTO staging.ST_OPORTUNIDADES as tgt
USING public.oportunidades AS src
ON (tgt.id = src.id)

WHEN MATCHED THEN
	UPDATE SET
	  lead_id              = src.lead_id
	, vendedor             = src.vendedor
	, data_abertura        = src.data_abertura
	, data_fechamento      = src.data_fechamento
	, stage                = src.stage
	, valor_mrr            = src.valor_mrr
	, valor_anual          = src.valor_anual
	, moeda                = src.moeda
	, motivo_perda         = src.motivo_perda
	, concorrente          = src.concorrente
	, numero_reunioes      = src.numero_reunioes
	, proposta_enviada     = src.proposta_enviada

WHEN NOT MATCHED THEN
	INSERT (
	  id
	, lead_id
	, vendedor
	, data_abertura
	, data_fechamento
	, stage
	, valor_mrr
	, valor_anual
	, moeda
	, motivo_perda
	, concorrente
	, numero_reunioes
	, proposta_enviada
	)
	VALUES(
	  src.id
	, src.lead_id
	, src.vendedor
	, src.data_abertura
	, src.data_fechamento
	, src.stage
	, src.valor_mrr
	, src.valor_anual
	, src.moeda
	, src.motivo_perda
	, src.concorrente
	, src.numero_reunioes
	, src.proposta_enviada
	)

WHEN NOT MATCHED BY SOURCE THEN
	DELETE;

END;
$$;