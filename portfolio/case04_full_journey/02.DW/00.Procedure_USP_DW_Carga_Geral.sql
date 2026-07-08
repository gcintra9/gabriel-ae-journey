CREATE OR REPLACE PROCEDURE USP_DW_CARGA_GERAL()
LANGUAGE plpgsql
AS $$
BEGIN

    -----------------------------------------
    -- 1. DIMENSÕES INDEPENDENTES
    -----------------------------------------
    CALL USP_DW_CARGA_LEADS();
    CALL USP_DW_CARGA_VENDEDORES();
    CALL USP_DW_CARGA_METAS();
    CALL USP_D_CARGA_CALENDARIO();
    CALL USP_DW_CARGA_CANAL();

    -----------------------------------------
    -- 2. DIMENSÃO DEPENDENTE
    -- (depende de dim_leads e dim_vendedor)
    -----------------------------------------
    CALL USP_DW_CARGA_DIM_OPORTUNIDADE();

    -----------------------------------------
    -- 3. FATO 1:1 COM DIM_OPORTUNIDADES
    -----------------------------------------
    CALL USP_DW_CARGA_OPORTUNIDADES();

    -----------------------------------------
    -- 4. FATOS DEPENDENTES DE OPORTUNIDADES
    -----------------------------------------
    CALL USP_DW_CARGA_ATIVIDADES();
    CALL USP_DW_CARGA_CONTRATOS();
    CALL USP_DW_CARGA_FACT_LEADS();
    CALL USP_DW_CARGA_CUSTOS();
END;
$$;