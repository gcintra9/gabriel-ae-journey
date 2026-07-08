CREATE OR REPLACE PROCEDURE USP_DW_CARGA_OPORTUNIDADES()
LANGUAGE plpgsql
AS $$
BEGIN
 
-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------
 
CREATE TABLE IF NOT EXISTS dw.fact_oportunidades
(
  id                  NUMERIC (15) PRIMARY KEY REFERENCES dw.dim_oportunidades(id)
, data_abertura       DATE
, data_fechamento     DATE
, ciclo_dias          INTEGER
, flag_anomalia_data  BOOLEAN
, valor_mrr           NUMERIC (10,2)
, valor_anual         NUMERIC (10,2)
, qtd_reunioes        INTEGER
);
 
------------------------------
-- LIMPA E POPULA A TABELA DO DW
------------------------------
 
MERGE INTO dw.fact_oportunidades AS tgt
USING tratamento.VW_F_OPORTUNIDADES AS src
ON (tgt.id = src.id)
 
WHEN MATCHED THEN
	UPDATE SET
	  data_abertura       = src.data_abertura
	, data_fechamento     = src.data_fechamento
	, ciclo_dias          = src.ciclo_dias
	, flag_anomalia_data  = src.flag_anomalia_data
	, valor_mrr           = src.valor_mrr
	, valor_anual         = src.valor_anual
	, qtd_reunioes        = src.qtd_reunioes
 
WHEN NOT MATCHED THEN
	INSERT (
	  id
	, data_abertura
	, data_fechamento
	, ciclo_dias
	, flag_anomalia_data
	, valor_mrr
	, valor_anual
	, qtd_reunioes
	)
	VALUES (
	  src.id
	, src.data_abertura
	, src.data_fechamento
	, src.ciclo_dias
	, src.flag_anomalia_data
	, src.valor_mrr
	, src.valor_anual
	, src.qtd_reunioes
	)
 
WHEN NOT MATCHED BY SOURCE THEN
	DELETE;
 
END;
$$;