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