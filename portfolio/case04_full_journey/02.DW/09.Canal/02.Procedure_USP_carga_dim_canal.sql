CREATE OR REPLACE PROCEDURE USP_DW_CARGA_CANAL()
LANGUAGE plpgsql
AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

CREATE TABLE IF NOT EXISTS dw.dim_canal
(
    chave_canal VARCHAR(100) PRIMARY KEY
  , canal       VARCHAR(50)
  , subcanal    VARCHAR(50)
);

-----------------------
-- LIMPA A TABELA DO DW
-----------------------

TRUNCATE TABLE dw.dim_canal;

------------------------
-- POPULA A TABELA DO DW
------------------------

INSERT INTO dw.dim_canal
(
      chave_canal
    , canal
    , subcanal
)
SELECT
      chave_canal
    , canal
    , subcanal
FROM tratamento.VW_D_CANAL;

END;
$$;