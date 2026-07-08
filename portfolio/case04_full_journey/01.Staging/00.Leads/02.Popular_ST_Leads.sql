TRUNCATE TABLE staging.ST_LEADS

INSERT INTO staging.ST_LEADS
(
  id
, nome
, email
, telefone
, empresa
, cargo
, segmento
, porte
, canal
, subcanal
, data_entrada
, status
, motivo_perda
, lead_score
, cidade
, estado
, pais
)
SELECT
	  id
	, nome
	, email
	, telefone
	, empresa
	, cargo
	, segmento
	, porte
	, canal
	, subcanal
	, data_entrada
	, status
	, motivo_perda
	, lead_score
	, cidade
	, estado
	, pais
FROM
	public.leads;