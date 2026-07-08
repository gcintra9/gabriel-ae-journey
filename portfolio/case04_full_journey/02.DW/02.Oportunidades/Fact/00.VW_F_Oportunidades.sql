CREATE OR REPLACE VIEW tratamento.VW_F_OPORTUNIDADES AS
	SELECT
		  id                                                    AS id
		, data_abertura                                         AS data_abertura
		, data_fechamento                                       AS data_fechamento
		, CASE 
		    WHEN data_fechamento IS NOT NULL 
		    THEN data_fechamento - data_abertura 
		    ELSE CURRENT_DATE - data_abertura    -- oportunidade ainda aberta
		  END                                                   AS ciclo_dias
		, CASE
		    WHEN data_fechamento < data_abertura THEN TRUE
		    ELSE FALSE
		  END                                                   AS flag_anomalia_data
		, valor_mrr                                             AS valor_mrr
		, valor_anual                                           AS valor_anual
		, numero_reunioes                                       AS qtd_reunioes
	FROM staging.st_oportunidades;