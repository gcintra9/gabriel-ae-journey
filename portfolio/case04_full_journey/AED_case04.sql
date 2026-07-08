-- CASE 04 - Full Journey

/*

Após reunião com Diego, Diretor Comercial da empresa Enterprise, estas são as informações e dores observadas:

Stakeholder 1 — Diego, Diretor Comercial
"Meu maior problema hoje é que não sei onde estou perdendo negócio. Sei que o time fecha, mas não sei se estamos fechando os leads certos ou se estamos
desperdiçando esforço em leads que nunca vão converter. Quero entender o ciclo de cada vendedor — quem fecha rápido, quem demora, quem tem win rate alto
mas ticket baixo. Também preciso de uma visão do funil para saber onde os leads estão travando. Se estão travando na reunião, é problema de qualificação.
Se estão travando na proposta, é problema de precificação ou concorrência. Hoje eu olho isso tudo em planilha e perco horas toda segunda-feira."

Dores: visibilidade do funil por stage, performance comparativa entre vendedores, ciclo de fechamento, relação entre win rate e ticket médio.

Leads certos: mapear o ICP → entender o perfil de clientes que tem um % maior de fechamento, ciclo com tempo dentro da média, ticket médio bom
Informações dos vendedores → Levantamento e rankeamento dos vendedores pelo ciclo, TKM, winrate
Funil de jornada do lead → Entender se existem gargalos em cada etapa (winrate da etapa fraco) e entender se existe alguma etapa com um volume alto de leads estacionado.


Primeiramente, é necessário conferir as tables que temos para entender melhor sua composição

A partir de um: */

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'

/*

temos a informação das tabelas disponíveis:
"leads"
"oportunidades"
"atividades"
"contratos"
"custos_canal"
"metas_vendedor"

Para as análises necessárias para a criação do dashboard que vai assitir Diego e sua equipe, vamos utilizar estas tabelas:

"leads"
"oportunidades"
"atividades"
"contratos"
"metas_vendedor"

Fazendo para cada tabela esta consulta é possível entender a composição das tabelas

Tabela leads:
Chave primária: leads.id (também é a única coluna que não pode ser nula)
Formatos das colunas: OK

*/

SELECT
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.character_maximum_length,
    c.numeric_precision,
    c.numeric_scale,
    c.is_nullable,
    c.column_default,

    -- PK
    CASE WHEN pk.column_name IS NOT NULL THEN true ELSE false END AS is_primary_key,

    -- FK
    CASE WHEN fk.column_name IS NOT NULL THEN true ELSE false END AS is_foreign_key,

    fk.foreign_table,
    fk.foreign_column

FROM information_schema.columns c

-- PRIMARY KEY
LEFT JOIN (
    SELECT kcu.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'leads'
      AND tc.constraint_type = 'PRIMARY KEY'
) pk
ON pk.column_name = c.column_name

-- FOREIGN KEY
LEFT JOIN (
    SELECT
        kcu.column_name,
        ccu.table_name AS foreign_table,
        ccu.column_name AS foreign_column
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.table_name = 'leads'
      AND tc.constraint_type = 'FOREIGN KEY'
) fk
ON fk.column_name = c.column_name

WHERE c.table_name = 'leads'
ORDER BY c.ordinal_position;


-- Analisando agora a composição da tabela de leads com a query:

SELECT * FROM leads LIMIT 100

-- Da tabela de leads vamos trazer as colunas:
SELECT
	  id
	, nome
	, email
	, telefone
	, empresa
	, cargo
	, segmento
	, porte
	, data_entrada
	, status
	, motivo_perda
	, lead_score
	, cidade
	, estado
	, pais
FROM
	leads

-- Foram eliminadas as colunas canal, subcanal, utm_source, utm_medium, utm_campaign, uma vez que elas falam da origem do lead e não das dores apresentadas por Diego

/* Tabela oportunidades:
Chave primária: oportunidade.id (também é a única coluna que não pode ser nula)
Chave secundária: oportunidade.lead_id
Formatos das colunas: OK

*/

SELECT
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.character_maximum_length,
    c.numeric_precision,
    c.numeric_scale,
    c.is_nullable,
    c.column_default,

    -- PK
    CASE WHEN pk.column_name IS NOT NULL THEN true ELSE false END AS is_primary_key,

    -- FK
    CASE WHEN fk.column_name IS NOT NULL THEN true ELSE false END AS is_foreign_key,

    fk.foreign_table,
    fk.foreign_column

FROM information_schema.columns c

-- PRIMARY KEY
LEFT JOIN (
    SELECT kcu.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'oportunidades'
      AND tc.constraint_type = 'PRIMARY KEY'
) pk
ON pk.column_name = c.column_name

-- FOREIGN KEY
LEFT JOIN (
    SELECT
        kcu.column_name,
        ccu.table_name AS foreign_table,
        ccu.column_name AS foreign_column
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.table_name = 'oportunidades'
      AND tc.constraint_type = 'FOREIGN KEY'
) fk
ON fk.column_name = c.column_name

WHERE c.table_name = 'oportunidades'
ORDER BY c.ordinal_position;


-- Analisando agora a composição da tabela de oportunidades com a query:

SELECT * FROM oportunidades LIMIT 100

-- Da tabela de oportunidades vamos trazer as colunas:

SELECT
	  id
	, lead_id
	, vendedor
	, squad
	, data_abertura
	, data_fechamento
	, stage
	, valor_mrr
	, valor_anual
	, motivo_perda
	, concorrente
	, numero_reunioes
	, proposta_enviada
FROM oportunidades 

-- A coluna BRL se mantém na base uma vez que existem valores além de BRL (2,6% da base é USD)

/* Tabela atividades:
Chave primária: atividades.id (também é a única coluna que não pode ser nula)
Chave secundária: atividades.oportunidade_id
Formatos das colunas: OK

*/

SELECT
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.character_maximum_length,
    c.numeric_precision,
    c.numeric_scale,
    c.is_nullable,
    c.column_default,

    -- PK
    CASE WHEN pk.column_name IS NOT NULL THEN true ELSE false END AS is_primary_key,

    -- FK
    CASE WHEN fk.column_name IS NOT NULL THEN true ELSE false END AS is_foreign_key,

    fk.foreign_table,
    fk.foreign_column

FROM information_schema.columns c

-- PRIMARY KEY
LEFT JOIN (
    SELECT kcu.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'atividades'
      AND tc.constraint_type = 'PRIMARY KEY'
) pk
ON pk.column_name = c.column_name

-- FOREIGN KEY
LEFT JOIN (
    SELECT
        kcu.column_name,
        ccu.table_name AS foreign_table,
        ccu.column_name AS foreign_column
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.table_name = 'atividades'
      AND tc.constraint_type = 'FOREIGN KEY'
) fk
ON fk.column_name = c.column_name

WHERE c.table_name = 'atividades'
ORDER BY c.ordinal_position;


-- Analisando agora a composição da tabela de atividades com a query:

SELECT * FROM atividades LIMIT 100

-- Da tabela de atividades vamos trazer as colunas:

SELECT
	  id
	, oportunidade_id
	, tipo
	, data_atividade
	, hora_atividade
	, compareceu
	, duracao_min
	, canal_atividade
	, responsavel
FROM atividades 

-- A coluna anotacao foi eliminada pois para este tipo de análise não tem importância



/* Tabela contratos:
Chave primária: contratos.id (também é a única coluna que não pode ser nula)
Chave secundária: contratos.oportunidade_id
Formatos das colunas: OK

*/

SELECT
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.character_maximum_length,
    c.numeric_precision,
    c.numeric_scale,
    c.is_nullable,
    c.column_default,

    -- PK
    CASE WHEN pk.column_name IS NOT NULL THEN true ELSE false END AS is_primary_key,

    -- FK
    CASE WHEN fk.column_name IS NOT NULL THEN true ELSE false END AS is_foreign_key,

    fk.foreign_table,
    fk.foreign_column

FROM information_schema.columns c

-- PRIMARY KEY
LEFT JOIN (
    SELECT kcu.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'contratos'
      AND tc.constraint_type = 'PRIMARY KEY'
) pk
ON pk.column_name = c.column_name

-- FOREIGN KEY
LEFT JOIN (
    SELECT
        kcu.column_name,
        ccu.table_name AS foreign_table,
        ccu.column_name AS foreign_column
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.table_name = 'contratos'
      AND tc.constraint_type = 'FOREIGN KEY'
) fk
ON fk.column_name = c.column_name

WHERE c.table_name = 'contratos'
ORDER BY c.ordinal_position;


-- Analisando agora a composição da tabela de contratos com a query:

SELECT * FROM contratos LIMIT 100

-- Da tabela de contratos vamos trazer as colunas:

SELECT
	  id
	, oportunidade_id
	, data_inicio
	, data_cancelamento
	, data_renovacao
	, plano
	, mrr
	, desconto_perc
	, mrr_bruto
	, periodicidade
	, motivo_cancelamento
	, nps_score
	, csm_responsavel
FROM contratos 

/* Tabela metas_vendedor:
Chave primária: metas_vendedor.id (também é a única coluna que não pode ser nula)
Formatos das colunas: OK

*/

SELECT
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.character_maximum_length,
    c.numeric_precision,
    c.numeric_scale,
    c.is_nullable,
    c.column_default,

    -- PK
    CASE WHEN pk.column_name IS NOT NULL THEN true ELSE false END AS is_primary_key,

    -- FK
    CASE WHEN fk.column_name IS NOT NULL THEN true ELSE false END AS is_foreign_key,

    fk.foreign_table,
    fk.foreign_column

FROM information_schema.columns c

-- PRIMARY KEY
LEFT JOIN (
    SELECT kcu.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'metas_vendedor'
      AND tc.constraint_type = 'PRIMARY KEY'
) pk
ON pk.column_name = c.column_name

-- FOREIGN KEY
LEFT JOIN (
    SELECT
        kcu.column_name,
        ccu.table_name AS foreign_table,
        ccu.column_name AS foreign_column
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.table_name = 'metas_vendedor'
      AND tc.constraint_type = 'FOREIGN KEY'
) fk
ON fk.column_name = c.column_name

WHERE c.table_name = 'metas_vendedor'
ORDER BY c.ordinal_position;


-- Analisando agora a composição da tabela de metas_vendedor com a query:

SELECT * FROM metas_vendedor LIMIT 100

-- Da tabela de metas_vendedor vamos trazer as colunas:

SELECT
	  id
	, vendedor
	, mes_ref
	, meta_oportunidades
	, meta_mrr
	, meta_win_rate
FROM metas_vendedor 


/* Agora vamos começar pelas dimensões que serão criadas:

Após isso foram geradas as procedures para a criação e população de cada base, por fim uma procedure para a execução de todas as procedures

A USP_ST_Carga_geral, com isso temos nossa staging preenchida.

O próximo passo é a análise exploratória dos dados de cada uma dessas tabelas para realização do seu tratamento e envio ao DW na sua forma ideal.