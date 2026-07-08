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