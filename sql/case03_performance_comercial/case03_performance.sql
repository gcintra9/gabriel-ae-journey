/* case03

/*
Observação:
As tabelas do case possuem PKs únicas.
Os DISTINCT foram mantidos apenas quando necessários para evitar multiplicação causada por JOINs.
*/

Nível 1 — Aquecimento (SELECTs + agregações) */

-- 1. Qual o ticket médio (valor_mrr) por segmento de lead? Mostre só segmentos com mais de 5 oportunidades ganhas, ordenado do maior ticket para o menor.

SELECT
	l.segmento,
	SUM(c.mrr)::money AS total,
	COUNT(c.id) AS total_pedido,
	ROUND(AVG(c.mrr),2)::money AS ticket_medio
FROM leads l
JOIN oportunidades o ON l.id = o.lead_id
JOIN contratos c ON o.id = c.oportunidade_id
WHERE o.stage = 'fechado_ganho'
GROUP BY l.segmento
HAVING COUNT(o.id) > 5
ORDER BY ticket_medio DESC;


-- 2. Quantos leads entraram por mês em 2025? Mostre mês, quantidade e acumulado até aquele mês.

WITH leads_mes AS(
    SELECT
        DATE_TRUNC('month', data_entrada) AS mes,
        COUNT(id) AS qtd_leads,
        COUNT(id) FILTER (WHERE status = 'qualificado') AS qtd_qualificados,
        COUNT(id) FILTER (WHERE status = 'desqualificado') AS qtd_desqualificados
    FROM leads
    WHERE data_entrada >= '2025-01-01'
      AND data_entrada < '2026-01-01'
    GROUP BY DATE_TRUNC('month', data_entrada)
)

SELECT
	TO_CHAR(TO_DATE(mes::text, 'MM'), 'Mon') AS nome_mes,
	qtd_leads,
	SUM(qtd_leads) OVER(ORDER BY mes) AS leads_acumulados,
    qtd_qualificados,
    qtd_desqualificados
FROM leads_mes
ORDER BY mes;

/* 3. Qual o tempo médio de ciclo de fechamento (em dias) por vendedor? Considere apenas oportunidades fechadas (ganhas ou perdidas).
Ordene do ciclo mais curto para o mais longo. */

SELECT
	vendedor,
	ROUND(AVG(EXTRACT(EPOCH FROM (data_fechamento - data_abertura)) / 86400),0) AS ciclo_medio_dias
FROM oportunidades
WHERE stage IN ('fechado_ganho', 'fechado_perdido')
GROUP BY vendedor
ORDER BY ciclo_medio_dias;

/* Nível 2 — JOINs + lógica de negócio */

-- 4. Liste os leads que viraram oportunidade mas nunca tiveram nenhuma atividade registrada. Mostre nome do lead, empresa, vendedor e stage atual.

SELECT
	l.nome,
	l.empresa,
	o.vendedor,
	o.stage
FROM leads l
JOIN oportunidades o
	ON l.id = o.lead_id
LEFT JOIN atividades a
	ON o.id = a.oportunidade_id
WHERE a.id IS NULL;

/* 5. Para cada vendedor, mostre: total de oportunidades, total de ganhas, total de perdidas, win rate em % e MRR total dos contratos ativos.
Tudo em uma única query. */

WITH oportunidades_vendedor AS(
	SELECT
		o.vendedor,
		COUNT(DISTINCT o.id) AS total_oportunidades,
		COUNT(DISTINCT o.id) FILTER(WHERE stage = 'fechado_ganho') AS oportunidades_ganhas,
		COUNT(DISTINCT o.id) FILTER(WHERE stage = 'fechado_perdido') AS oportunidades_perdidas,
		SUM(c.mrr) FILTER(WHERE data_cancelamento IS NULL) AS mrr_total_contratos_ativos
	FROM oportunidades o
	LEFT JOIN contratos c
		ON o.id = c.oportunidade_id
	GROUP BY o.vendedor
)
SELECT
	vendedor,
	total_oportunidades,
	oportunidades_ganhas,
	oportunidades_perdidas,
	ROUND(oportunidades_ganhas::numeric / NULLIF((oportunidades_ganhas + oportunidades_perdidas),0)* 100,1) AS win_rate_perc,
	mrr_total_contratos_ativos::money
FROM oportunidades_vendedor
ORDER BY win_rate_perc DESC;

-- 6. Quais contratos estão ativos há mais de 6 meses? Mostre: nome do lead, empresa, plano, MRR, data de início e quantos dias ativo até hoje.

SELECT
	l.nome,
	l.empresa,
	c.plano,
	c.mrr::money,
	c.data_inicio,
	CURRENT_DATE - c.data_inicio AS dias_ativo
FROM leads l
JOIN oportunidades o
	ON l.id = o.lead_id
JOIN contratos c
	ON o.id = c.oportunidade_id
WHERE c.data_inicio <= CURRENT_DATE - INTERVAL '6 months'
	AND c.data_cancelamento IS NULL
ORDER BY dias_ativo DESC;



-- Nível 3 — CTEs + Window Functions
-- 7. Para cada mês, mostre os 3 vendedores com maior MRR fechado naquele mês. Use window function — não subquery.
WITH vendas_mes AS(
	SELECT
		DATE_TRUNC('month', c.data_inicio) AS mes,
		o.vendedor,
		SUM(c.mrr) as mrr
	FROM oportunidades o
	JOIN contratos c
		ON o.id = c.oportunidade_id
	GROUP BY DATE_TRUNC('month', c.data_inicio), vendedor
),
rank_geral AS(
	SELECT
		mes,
		vendedor,
		mrr,
		DENSE_RANK() OVER(PARTITION BY mes ORDER BY mrr DESC) AS rank_mrr
	FROM vendas_mes
)
SELECT
	mes,
	vendedor,
	mrr::money,
	rank_mrr
FROM rank_geral
WHERE rank_mrr <= 3
ORDER BY mes, rank_mrr;

/* 8. Calcule a taxa de conversão por canal mês a mês. Mostre: canal, mês, leads qualificados, oportunidades abertas, contratos fechados
 e taxa de conversão (contratos/leads qualificados). Inclua variação MoM da taxa. */

WITH jornada_lead AS(
	SELECT
		DATE_TRUNC('month',l.data_entrada)::date AS mes_safra,
		l.canal,
		COUNT(DISTINCT l.id) FILTER(WHERE l.status = 'qualificado') AS leads_qualificados,
		COUNT(DISTINCT o.id) FILTER(WHERE o.stage = 'reuniao_agendada') AS oportunidades_abertas,
		COUNT(DISTINCT c.id) AS contratos_fechados
	FROM leads l
	JOIN oportunidades o
		ON l.id = o.lead_id
	LEFT JOIN contratos c
		ON o.id = c.oportunidade_id
	GROUP BY DATE_TRUNC('month',l.data_entrada)::date, l.canal
),
conversao_leads AS(
	SELECT
		mes_safra,
		canal,
		leads_qualificados,
		oportunidades_abertas,
		contratos_fechados,
		ROUND(contratos_fechados::numeric / NULLIF(leads_qualificados,0)*100,1) AS taxa_conversao
	FROM jornada_lead
),
conversao_pm AS(
	SELECT
		mes_safra,
		canal,
		leads_qualificados,
		oportunidades_abertas,
		contratos_fechados,
		taxa_conversao,
		LAG(taxa_conversao) OVER(PARTITION BY canal ORDER BY mes_safra) AS taxa_pm
	FROM conversao_leads
)
SELECT
	mes_safra,
	canal,
	leads_qualificados,
	oportunidades_abertas,
	contratos_fechados,
	taxa_conversao,
	ROUND((taxa_conversao - taxa_pm) / NULLIF(taxa_pm,0)*100,1) AS taxa_mom
FROM conversao_pm
ORDER BY canal, mes_safra;

/* 9. Identifique vendedores com performance abaixo da média do time. Defina "abaixo da média" como win rate menor que a média geral.
Use CTE para calcular a média do time separadamente antes de comparar. */

WITH jornada_vendedor AS(
	SELECT
		o.vendedor,
		COUNT(DISTINCT o.id) FILTER(WHERE stage IN ('fechado_ganho', 'fechado_perdido')) AS oportunidades_trabalhadas,
		COUNT (DISTINCT c.id) AS contratos_fechados
	FROM oportunidades o
	LEFT JOIN contratos c
		ON o.id = c.oportunidade_id
	GROUP BY o.vendedor
),
winrate_vendedor AS(
	SELECT
		vendedor,
		oportunidades_trabalhadas,
		contratos_fechados,
		ROUND(contratos_fechados::numeric / NULLIF(oportunidades_trabalhadas,0)*100,1) AS winrate
	FROM jornada_vendedor
),
winrate_geral AS(
	SELECT
	ROUND(AVG(winrate),2) AS media_geral
	FROM winrate_vendedor
)
SELECT
	a.vendedor,
	a.winrate,
	b.media_geral,
	winrate-media_geral AS percent_abaixo
FROM winrate_vendedor a
CROSS JOIN winrate_geral b
WHERE a.winrate < b.media_geral
ORDER BY percent_abaixo DESC;


/*-- 10. Construa uma análise de coorte simplificada: agrupe os leads pelo mês de entrada e mostre, para cada coorte, quantos viraram oportunidade,
quantos viraram contrato e qual o MRR médio gerado. Ordene pelo mês de entrada. */

SELECT
	DATE_TRUNC('month', l.data_entrada)::date AS mes_safra,
	COUNT(DISTINCT l.id) AS total_leads,
	COUNT(DISTINCT l.id) FILTER(WHERE status = 'qualificado') AS lead_qualificado,
	COUNT(DISTINCT o.id) AS oportunidade,
	COUNT(DISTINCT o.id) FILTER (WHERE stage = 'fechado_ganho') AS oportunidade_fechada,
	COUNT(DISTINCT c.id) AS contratos_fechados,
	AVG(c.mrr)::money AS mrr_medio
FROM leads l
LEFT JOIN oportunidades o
	ON l.id = o.lead_id
LEFT JOIN contratos c
	ON o.id = c.oportunidade_id
GROUP BY DATE_TRUNC('month', l.data_entrada)::date
ORDER BY mes_safra ASC;

-- Nível 4 — Desafio AE
/* 11. Construa um funil de conversão completo com taxa de conversão entre cada etapa:
Leads totais
→ Leads qualificados        (% do total)
→ Oportunidades abertas     (% dos qualificados)
→ Oportunidades ganhas      (% das abertas)
→ Contratos ativos          (% das ganhas)
→ MRR total ativo           (valor)
Tudo em uma única query com CTEs. O resultado deve ser uma linha por etapa com nome da etapa, quantidade e taxa de conversão da etapa anterior.
*/

-- Conversão por Etapa em coluna
WITH leads_agg AS(
	SELECT
		COUNT(DISTINCT id) AS total_leads,
		COUNT(DISTINCT id) FILTER(WHERE status = 'qualificado')  AS qualificados,
		COUNT(DISTINCT id) FILTER(WHERE status = 'desqualificado') AS desqualificados,
		COUNT(DISTINCT id) FILTER(WHERE status = 'novo') AS novos
	FROM leads
),
oportunidades_agg AS(
	SELECT
		COUNT(DISTINCT id) FILTER(WHERE stage NOT IN ('fechado_ganho', 'fechado_perdido')) AS oportunidades_abertas,
		COUNT(DISTINCT id) FILTER(WHERE stage IN ('fechado_ganho', 'fechado_perdido')) AS oportunidades_fechadas,
		COUNT(DISTINCT id) FILTER(WHERE stage = 'fechado_perdido') AS oportunidades_perdidas,
		COUNT(DISTINCT id) FILTER(WHERE stage = 'fechado_ganho') AS oportunidades_ganhas,
		COUNT(DISTINCT id) AS total_oportunidades
	FROM oportunidades
),
contratos_agg AS(
	SELECT
		COUNT(DISTINCT id) FILTER(WHERE data_cancelamento IS NULL) AS contratos_ativos,
		COUNT(DISTINCT id) FILTER(WHERE data_cancelamento IS NOT NULL) AS contratos_cancelados,
		COUNT(DISTINCT id) AS total_contratos,
		SUM(mrr) FILTER(WHERE data_cancelamento IS NULL) AS mrr_ativo,
		SUM(mrr) AS total_mrr
	FROM contratos
),
leads_quali AS(
	SELECT
		total_leads,
		qualificados,
		ROUND((qualificados::numeric / NULLIF(total_leads,0))*100,1) AS perc_leads_quali,
		ROUND((total_leads::numeric / NULLIF(total_leads,0))*100,1) AS perc_leads_totais
		FROM leads_agg
),
oportunidades_calc AS(
	SELECT
		oportunidades_abertas,
		oportunidades_ganhas,
		ROUND((oportunidades_abertas::numeric / NULLIF(total_oportunidades,0))*100,1) AS perc_opp_abertas,
		ROUND((oportunidades_ganhas::numeric / NULLIF(total_oportunidades,0))*100,1) AS perc_opp_ganhas
	FROM oportunidades_agg
),
contratos_calc AS(
	SELECT
		contratos_ativos,
		ROUND((contratos_ativos::numeric / NULLIF(total_contratos,0))*100,1) AS perc_contratos_atv,
		total_mrr,
		mrr_ativo
	FROM contratos_agg
)
SELECT
	'Leads totais' AS etapa,
	total_leads AS quantidade,
	perc_leads_totais AS taxa_conversao
FROM leads_quali

UNION ALL

SELECT
	'Leads qualificados' AS etapa,
	qualificados AS quantidade,
	perc_leads_quali AS taxa_conversao
FROM leads_quali

UNION ALL

SELECT
	'Oportunidades abertas' AS etapa,
	oportunidades_abertas AS quantidade,
	perc_opp_abertas AS taxa_conversao
FROM oportunidades_calc

UNION ALL

SELECT
	'Oportunidades ganhas' AS etapa,
	oportunidades_ganhas AS quantidade,
	perc_opp_ganhas AS taxa_conversao
FROM oportunidades_calc

UNION ALL

SELECT
	'Contratos ativos' AS etapa,
	contratos_ativos AS quantidade,
	perc_contratos_atv AS taxa_conversao
FROM contratos_calc

UNION ALL

SELECT
	'MRR total ativo' AS etapa,
	mrr_ativo AS quantidade,
	NULL AS taxa_conversao
FROM contratos_calc;



/* 12. Detecte anomalias nos dados: liste todos os registros onde a data de fechamento da oportunidade é anterior à data de abertura,
ou onde o contrato tem data de início anterior ao fechamento da oportunidade. Mostre o tipo de anomalia, os IDs envolvidos e as datas conflitantes. */
WITH opp_diag AS(
	SELECT
		l.id AS lead_id,
		o.id AS opp_id,
		l.data_entrada,
		o.data_abertura,
		o.data_fechamento,
		CASE
			WHEN
				l.data_entrada > o.data_abertura AND o.data_abertura < o.data_fechamento
				THEN 'dt_entrada maior que abertura'
			WHEN
				l.data_entrada > o.data_abertura AND o.data_abertura > o.data_fechamento
				THEN 'dt_entrada maior que abertura e dt_abertura maior que fechamento'
			WHEN
				o.data_abertura > o.data_fechamento
				THEN 'dt_abertura maior que fechamento'
		ELSE NULL END AS motivo_anomalia,
		'Oportunidades' AS fonte
	FROM leads l
	JOIN oportunidades o
		ON l.id = o.lead_id
),
ctt_diag AS(
	SELECT
		o.id AS opp_id,
		c.id AS ctt_id,
		o.data_abertura,
		o.data_fechamento,
		c.data_inicio,
		CASE
			WHEN
				o.data_fechamento > c.data_inicio AND o.data_abertura < o.data_fechamento
				THEN 'dt_fechamento maior que inicio contrato'
			WHEN
				o.data_fechamento > c.data_inicio AND o.data_abertura > o.data_fechamento
				THEN 'dt_fechamento maior que inicio contrato e dt_abertura maior que fechamento'
		ELSE NULL END AS motivo_anomalia,
		'Contratos' AS fonte
	FROM oportunidades o
	JOIN contratos c
		ON o.id = c.oportunidade_id
)
SELECT
	opp_id AS ID,
	fonte,
	data_entrada,
	data_abertura,
	data_fechamento,
	NULL AS data_inicio,
	motivo_anomalia
FROM opp_diag
WHERE motivo_anomalia IN ('dt_entrada maior que abertura', 'dt_entrada maior que abertura e dt_abertura maior que fechamento', 'dt_abertura maior que fechamento')

UNION ALL

SELECT
	ctt_id AS ID,
	fonte,
	NULL AS data_entrada,
	data_abertura,
	data_fechamento,
	data_inicio,
	motivo_anomalia
FROM ctt_diag
WHERE motivo_anomalia IN ('dt_fechamento maior que inicio contrato', 'dt_fechamento maior que inicio contrato e dt_abertura maior que fechamento')


/* Resoluções alternativas para a questão 11.
11. Construa um funil de conversão completo com taxa de conversão entre cada etapa:
Leads totais
→ Leads qualificados        (% do total)
→ Oportunidades abertas     (% dos qualificados)
→ Oportunidades ganhas      (% das abertas)
→ Contratos ativos          (% das ganhas)
→ MRR total ativo           (valor)
Tudo em uma única query com CTEs. O resultado deve ser uma linha por etapa com nome da etapa, quantidade e taxa de conversão da etapa anterior.
*/


-- Conversão por Etapa em linha
WITH leads_agg AS(
	SELECT
		COUNT(DISTINCT id) AS total_leads,
		COUNT(DISTINCT id) FILTER(WHERE status = 'qualificado')  AS qualificados,
		COUNT(DISTINCT id) FILTER(WHERE status = 'desqualificado') AS desqualificados,
		COUNT(DISTINCT id) FILTER(WHERE status = 'novo') AS novos
	FROM leads
),
oportunidades_agg AS(
	SELECT
		COUNT(DISTINCT id) FILTER(WHERE stage NOT IN ('fechado_ganho', 'fechado_perdido')) AS oportunidades_abertas,
		COUNT(DISTINCT id) FILTER(WHERE stage IN ('fechado_ganho', 'fechado_perdido')) AS oportunidades_fechadas,
		COUNT(DISTINCT id) FILTER(WHERE stage = 'fechado_perdido') AS oportunidades_perdidas,
		COUNT(DISTINCT id) FILTER(WHERE stage = 'fechado_ganho') AS oportunidades_ganhas,
		COUNT(DISTINCT id) AS total_oportunidades
	FROM oportunidades
),
contratos_agg AS(
	SELECT
		COUNT(DISTINCT id) FILTER(WHERE data_cancelamento IS NULL) AS contratos_ativos,
		COUNT(DISTINCT id) FILTER(WHERE data_cancelamento IS NOT NULL) AS contratos_cancelados,
		COUNT(DISTINCT id) AS total_contratos,
		SUM(mrr) FILTER(WHERE data_cancelamento IS NULL) AS mrr_ativo,
		SUM(mrr) AS total_mrr
	FROM contratos
),
leads_quali AS(
	SELECT
		ROUND((qualificados::numeric / NULLIF(total_leads,0))*100,1) AS perc_leads_quali
		FROM leads_agg
),
oportunidades_calc AS(
	SELECT
		ROUND((oportunidades_abertas::numeric / NULLIF(total_oportunidades,0))*100,1) AS perc_opp_abertas,
		ROUND((oportunidades_ganhas::numeric / NULLIF(total_oportunidades,0))*100,1) AS perc_opp_ganhas
	FROM oportunidades_agg
),
contratos_calc AS(
	SELECT
		ROUND((contratos_ativos::numeric / NULLIF(total_contratos,0))*100,1) AS perc_contratos_atv,
		total_mrr,
		mrr_ativo
	FROM contratos_agg
)
SELECT
	a.perc_leads_quali,
	b.perc_opp_abertas,
	b.perc_opp_ganhas,
	c.perc_contratos_atv,
	c.mrr_ativo::money
FROM leads_quali a
CROSS JOIN oportunidades_calc b
CROSS JOIN contratos_calc c;

-- Conversão Topo Funil em coluna
WITH leads_agg AS(
	SELECT
		COUNT(DISTINCT id) AS total_leads,
		COUNT(DISTINCT id) FILTER(WHERE status = 'qualificado')  AS qualificados,
		COUNT(DISTINCT id) FILTER(WHERE status = 'desqualificado') AS desqualificados,
		COUNT(DISTINCT id) FILTER(WHERE status = 'novo') AS novos
	FROM leads
),
oportunidades_agg AS(
	SELECT
		COUNT(DISTINCT id) FILTER(WHERE stage NOT IN ('fechado_ganho', 'fechado_perdido')) AS oportunidades_abertas,
		COUNT(DISTINCT id) FILTER(WHERE stage IN ('fechado_ganho', 'fechado_perdido')) AS oportunidades_fechadas,
		COUNT(DISTINCT id) FILTER(WHERE stage = 'fechado_perdido') AS oportunidades_perdidas,
		COUNT(DISTINCT id) FILTER(WHERE stage = 'fechado_ganho') AS oportunidades_ganhas,
		COUNT(DISTINCT id) AS total_oportunidades
	FROM oportunidades
),
contratos_agg AS(
	SELECT
		COUNT(DISTINCT id) FILTER(WHERE data_cancelamento IS NULL) AS contratos_ativos,
		COUNT(DISTINCT id) FILTER(WHERE data_cancelamento IS NOT NULL) AS contratos_cancelados,
		COUNT(DISTINCT id) AS total_contratos,
		SUM(mrr) FILTER(WHERE data_cancelamento IS NULL) AS mrr_ativo,
		SUM(mrr) AS total_mrr
	FROM contratos
),
leads_quali AS(
	SELECT
		ROUND((qualificados::numeric / NULLIF(total_leads,0))*100,1) AS perc_leads_quali
		FROM leads_agg
),
oportunidades_calc AS(
	SELECT
		ROUND((a.oportunidades_abertas::numeric / NULLIF(b.total_leads,0))*100,1) AS perc_opp_abertas,
		ROUND((a.oportunidades_ganhas::numeric / NULLIF(b.total_leads,0))*100,1) AS perc_opp_ganhas
	FROM oportunidades_agg a
	CROSS JOIN leads_agg b
),
contratos_calc AS(
	SELECT
		ROUND((a.contratos_ativos::numeric / NULLIF(b.total_leads,0))*100,1) AS perc_contratos_atv,
		a.total_mrr,
		mrr_ativo
	FROM contratos_agg a
	CROSS JOIN leads_agg b
)
SELECT
	a.perc_leads_quali,
	b.perc_opp_abertas,
	b.perc_opp_ganhas,
	c.perc_contratos_atv,
	c.mrr_ativo::money
FROM leads_quali a
CROSS JOIN oportunidades_calc b
CROSS JOIN contratos_calc c;


-- Conversão Topo Funil em coluna
WITH leads_agg AS(
	SELECT
		COUNT(DISTINCT id) AS total_leads,
		COUNT(DISTINCT id) FILTER(WHERE status = 'qualificado')  AS qualificados,
		COUNT(DISTINCT id) FILTER(WHERE status = 'desqualificado') AS desqualificados,
		COUNT(DISTINCT id) FILTER(WHERE status = 'novo') AS novos
	FROM leads
),
oportunidades_agg AS(
	SELECT
		COUNT(DISTINCT id) FILTER(WHERE stage NOT IN ('fechado_ganho', 'fechado_perdido')) AS oportunidades_abertas,
		COUNT(DISTINCT id) FILTER(WHERE stage IN ('fechado_ganho', 'fechado_perdido')) AS oportunidades_fechadas,
		COUNT(DISTINCT id) FILTER(WHERE stage = 'fechado_perdido') AS oportunidades_perdidas,
		COUNT(DISTINCT id) FILTER(WHERE stage = 'fechado_ganho') AS oportunidades_ganhas,
		COUNT(DISTINCT id) AS total_oportunidades
	FROM oportunidades
),
contratos_agg AS(
	SELECT
		COUNT(DISTINCT id) FILTER(WHERE data_cancelamento IS NULL) AS contratos_ativos,
		COUNT(DISTINCT id) FILTER(WHERE data_cancelamento IS NOT NULL) AS contratos_cancelados,
		COUNT(DISTINCT id) AS total_contratos,
		SUM(mrr) FILTER(WHERE data_cancelamento IS NULL) AS mrr_ativo,
		SUM(mrr) AS total_mrr
	FROM contratos
),
leads_quali AS(
	SELECT
		total_leads,
		qualificados,
		ROUND((qualificados::numeric / NULLIF(total_leads,0))*100,1) AS perc_leads_quali,
		ROUND((total_leads::numeric / NULLIF(total_leads,0))*100,1) AS perc_leads_totais
		FROM leads_agg
),
oportunidades_calc AS(
	SELECT
		a.oportunidades_abertas,
		a.oportunidades_ganhas,
		ROUND((a.oportunidades_abertas::numeric / NULLIF(b.total_leads,0))*100,1) AS perc_opp_abertas,
		ROUND((a.oportunidades_ganhas::numeric / NULLIF(b.total_leads,0))*100,1) AS perc_opp_ganhas
	FROM oportunidades_agg a
	CROSS JOIN leads_agg b
),
contratos_calc AS(
	SELECT
		contratos_ativos,
		ROUND((a.contratos_ativos::numeric / NULLIF(b.total_leads,0))*100,1) AS perc_contratos_atv,
		total_mrr,
		mrr_ativo
	FROM contratos_agg a
	CROSS JOIN leads_agg b
)
SELECT
	'Leads totais' AS etapa,
	total_leads AS quantidade,
	perc_leads_totais AS taxa_conversao
FROM leads_quali

UNION ALL

SELECT
	'Leads qualificados' AS etapa,
	qualificados AS quantidade,
	perc_leads_quali AS taxa_conversao
FROM leads_quali

UNION ALL

SELECT
	'Oportunidades abertas' AS etapa,
	oportunidades_abertas AS quantidade,
	perc_opp_abertas AS taxa_conversao
FROM oportunidades_calc

UNION ALL

SELECT
	'Oportunidades ganhas' AS etapa,
	oportunidades_ganhas AS quantidade,
	perc_opp_ganhas AS taxa_conversao
FROM oportunidades_calc

UNION ALL

SELECT
	'Contratos ativos' AS etapa,
	contratos_ativos AS quantidade,
	perc_contratos_atv AS taxa_conversao
FROM contratos_calc

UNION ALL

SELECT
	'MRR total ativo' AS etapa,
	mrr_ativo AS quantidade,
	NULL AS taxa_conversao
FROM contratos_calc;
