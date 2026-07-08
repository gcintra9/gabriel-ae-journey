CREATE TABLE IF NOT EXISTS dw.dim_calendario
(
	  data DATE PRIMARY KEY
	, dia INTEGER
	, mes INTEGER
	, ano INTEGER
	, nome_mes VARCHAR(20)
	, semana INTEGER
	, dia_semana INTEGER
	, nome_dia VARCHAR(20)
	, dia_ano INTEGER
	, inicio_mes DATE
	, fim_mes DATE
	, inicio_trimestre DATE
	, trimestre_num INTEGER
	, inicio_ano DATE
	, mes_ano VARCHAR(10)
	, mes_ano_ordem INTEGER
);