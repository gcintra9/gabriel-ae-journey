CREATE TABLE IF NOT EXISTS staging.ST_OPORTUNIDADES
(
  id	             NUMERIC (15)	
, lead_id	         NUMERIC (15)	
, vendedor	       VARCHAR (100)
, data_abertura	   DATE	
, data_fechamento	 DATE	
, stage	           VARCHAR (30)
, valor_mrr	       NUMERIC (30)
, valor_anual	     NUMERIC (30)
, moeda	           VARCHAR (5)
, motivo_perda	   VARCHAR (100)
, concorrente	     VARCHAR (80)
, numero_reunioes	 INTEGER	
, proposta_enviada BOOLEAN
);