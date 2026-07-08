CREATE OR REPLACE PROCEDURE USP_ST_CARGA_ATIVIDADES()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

CREATE TABLE IF NOT EXISTS staging.ST_ATIVIDADES
(
  id              NUMERIC (15)
, oportunidade_id NUMERIC (15)
, tipo            VARCHAR (50)
, data_atividade  DATE 
, hora_atividade  TIME
, compareceu      BOOLEAN 
, duracao_min     INTEGER 
, canal_atividade VARCHAR (40)
, responsavel     VARCHAR (100)
);

------------------------------
-- LIMPA E POPULA A STAGE ÁREA
------------------------------

MERGE INTO staging.ST_ATIVIDADES as tgt
USING public.atividades AS src
ON (tgt.id = src.id)

WHEN MATCHED THEN
	UPDATE SET
	  oportunidade_id = src.oportunidade_id
	, tipo            = src.tipo
	, data_atividade  = src.data_atividade
	, hora_atividade  = src.hora_atividade
	, compareceu      = src.compareceu
	, duracao_min     = src.duracao_min
	, canal_atividade = src.canal_atividade
	, responsavel     = src.responsavel

WHEN NOT MATCHED THEN
	INSERT (
	  id
	, oportunidade_id
	, tipo
	, data_atividade
	, hora_atividade
	, compareceu
	, duracao_min
	, canal_atividade
	, responsavel
	)
	VALUES(
	  src.id
	, src.oportunidade_id
	, src.tipo
	, src.data_atividade
	, src.hora_atividade
	, src.compareceu
	, src.duracao_min
	, src.canal_atividade
	, src.responsavel
	)

WHEN NOT MATCHED BY SOURCE THEN
	DELETE;

END;
$$;