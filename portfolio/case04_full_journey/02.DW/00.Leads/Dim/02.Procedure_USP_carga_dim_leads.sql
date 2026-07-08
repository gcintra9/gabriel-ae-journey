CREATE OR REPLACE PROCEDURE USP_DW_CARGA_LEADS()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

CREATE TABLE IF NOT EXISTS dw.dim_LEADS
(
  id                  NUMERIC (15) PRIMARY KEY NOT NULL
, nome                VARCHAR (100)
, email               VARCHAR (80)
, telefone            VARCHAR (30)
, empresa             VARCHAR (100)
, cargo               VARCHAR (80)
, segmento            VARCHAR (50)
, porte               VARCHAR (20)
, canal               VARCHAR (50)
, subcanal            VARCHAR (50)
, status              VARCHAR (30)
, motivo_perda        VARCHAR (100)
, lead_score          INTEGER
, classificacao_score VARCHAR (20)
, cidade              VARCHAR (60)
, estado              CHAR    (2)
, pais                VARCHAR (30)
);

-----------------------------------
-- MERGE (UPSERT + DELETE ÓRFÃOS)
-----------------------------------

MERGE INTO dw.dim_leads AS tgt
USING tratamento.VW_D_LEADS AS src
ON (tgt.id = src.id)

WHEN MATCHED THEN
	UPDATE SET
	  nome                = src.nome
	, email               = src.email
	, telefone            = src.telefone
	, empresa             = src.empresa
	, cargo               = src.cargo
	, segmento            = src.segmento
	, porte               = src.porte
	, canal               = src.canal
	, subcanal            = src.subcanal
	, status              = src.status
	, motivo_perda        = src.motivo_perda
	, lead_score          = src.lead_score
	, classificacao_score = src.classificacao_score
	, cidade              = src.cidade
	, estado              = src.estado
	, pais                = src.pais

WHEN NOT MATCHED THEN
	INSERT (
	  id, nome, email, telefone, empresa, cargo, segmento, porte
	, canal, subcanal, status, motivo_perda, lead_score
	, classificacao_score, cidade, estado, pais
	)
	VALUES (
	  src.id, src.nome, src.email, src.telefone, src.empresa, src.cargo, src.segmento, src.porte
	, src.canal, src.subcanal, src.status, src.motivo_perda, src.lead_score
	, src.classificacao_score, src.cidade, src.estado, src.pais
	)

WHEN NOT MATCHED BY SOURCE THEN
	DELETE;

END;
$$;