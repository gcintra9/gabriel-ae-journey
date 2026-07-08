CREATE OR REPLACE PROCEDURE USP_DW_CARGA_ATIVIDADES()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

CREATE TABLE IF NOT EXISTS dw.fact_atividades
(
  id                    NUMERIC (15) PRIMARY KEY NOT NULL
, oportunidade_id       NUMERIC (15) REFERENCES dw.dim_oportunidades(id) 
, tipo                  VARCHAR (50)
, responsavel           VARCHAR (100)
, data_atividade        DATE 
, hora_atividade        TIME
, compareceu            BOOLEAN 
, duracao_min           INTEGER
, classificacao_duracao VARCHAR (25)
, canal_atividade       VARCHAR (40)
);

------------------------------
-- LIMPA E POPULA A STAGE ÁREA
------------------------------

MERGE INTO dw.fact_atividades as tgt
USING tratamento.VW_F_ATIVIDADES AS src
ON (tgt.id = src.id)

WHEN MATCHED THEN
	UPDATE SET
	  oportunidade_id       = src.oportunidade_id
	, tipo                  = src.tipo	
	, responsavel           = src.responsavel
	, data_atividade        = src.data_atividade
	, hora_atividade        = src.hora_atividade
	, compareceu            = src.compareceu
	, duracao_min           = src.duracao_min
	, classificacao_duracao = src.classificacao_duracao
	, canal_atividade       = src.canal_atividade

WHEN NOT MATCHED THEN
	INSERT (
	  id 
	, oportunidade_id 
	, tipo
	, responsavel
	, data_atividade 
	, hora_atividade
	, compareceu 
	, duracao_min
	, classificacao_duracao
	, canal_atividade
	)
	VALUES(
	  src.id 
	, src.oportunidade_id 
	, src.tipo
	, src.responsavel
	, src.data_atividade 
	, src.hora_atividade
	, src.compareceu 
	, src.duracao_min
	, src.classificacao_duracao
	, src.canal_atividade
	)

WHEN NOT MATCHED BY SOURCE THEN
	DELETE;

END;
$$;