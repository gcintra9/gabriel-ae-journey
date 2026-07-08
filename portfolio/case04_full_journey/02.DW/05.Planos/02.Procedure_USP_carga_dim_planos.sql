CREATE OR REPLACE PROCEDURE USP_D_CARGA_PLANOS()
LANGUAGE plpgsql

AS $$
BEGIN

-----------------------------
-- VERIFICA SE A TABLE EXISTE
-----------------------------

CREATE TABLE IF NOT EXISTS dw.dim_planos
(
  plano         VARCHAR (50) PRIMARY KEY NOT NULL
, periodicidade VARCHAR (20)
);

-----------------------
-- LIMPA A TABELA DO DW
-----------------------

TRUNCATE TABLE dw.dim_planos;

------------------------
-- POPULA A TABELA DO DW
------------------------

INSERT INTO dw.dim_planos
(
  plano
, periodicidade
)

SELECT DISTINCT
  plano
, periodicidade
FROM tratamento.VW_D_PLANOS
WHERE plano IS NOT NULL;


END;
$$;