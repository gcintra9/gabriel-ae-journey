CREATE OR REPLACE PROCEDURE USP_D_CARGA_CALENDARIO()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

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

-----------------------
-- LIMPA A TABELA DO DW
-----------------------

TRUNCATE TABLE dw.dim_calendario;

------------------------
-- POPULA A TABELA DO DW
------------------------

INSERT INTO dw.dim_calendario
(
    data
  , dia
  , mes
  , ano
  , nome_mes
  , semana
  , dia_semana
  , nome_dia
  , dia_ano
  , inicio_mes
  , fim_mes
  , inicio_trimestre
  , trimestre_num
  , inicio_ano
  , mes_ano
  , mes_ano_ordem
)

SELECT DISTINCT
    data
  , dia
  , mes
  , ano
  , nome_mes
  , semana
  , dia_semana
  , nome_dia
  , dia_ano
  , inicio_mes
  , fim_mes
  , inicio_trimestre
  , trimestre_num
  , inicio_ano
  , mes_ano
  , mes_ano_ordem
FROM tratamento.VW_D_CALENDARIO;

END;
$$;