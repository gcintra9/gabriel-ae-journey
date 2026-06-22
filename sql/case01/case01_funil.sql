-- case01_funil

-- 1º) Top 10 clientes por valor nos últimos 12 meses com RANK
WITH mrr_clientes AS(
	SELECT
		l.nome AS cliente,
		SUM(c.mrr) AS total_mrr
	FROM leads l
	INNER JOIN oportunidades o
		ON l.id = o.lead_id
	INNER JOIN contratos c
		ON o.id = c.oportunidade_id
	WHERE c.data_inicio >= (date_trunc('month', CURRENT_DATE) - INTERVAL '12 months')
  AND c.data_inicio <= CURRENT_DATE
	GROUP BY l.nome
),
ranked AS(
SELECT
	cliente,
	total_mrr,
	DENSE_RANK() OVER(ORDER BY total_mrr DESC) AS ranking
FROM mrr_clientes
)
SELECT
	cliente,
	total_mrr,
	ranking
FROM ranked
WHERE ranking <= 10
ORDER BY ranking ASC;

-- 2º) Variação MoM de receita por segmento

WITH mrr_mensal AS(
	SELECT
	l.segmento,
	date_trunc('month', c.data_inicio) AS mes,
	SUM(c.mrr) as total_mrr
	FROM leads l
	INNER JOIN oportunidades o
		ON l.id = o.lead_id
	INNER JOIN contratos c
		ON o.id = c.oportunidade_id
	WHERE c.data_inicio >= (date_trunc('month', CURRENT_DATE) - INTERVAL '12 months')
	AND c.data_inicio <= CURRENT_DATE
	GROUP BY l.segmento, date_trunc('month', c.data_inicio)
),
mom AS (
    SELECT
        segmento,
        mes,
        total_mrr,
        LAG(total_mrr) OVER (
            PARTITION BY segmento
            ORDER BY mes
        ) AS receita_mes_anterior
    FROM mrr_mensal
)
SELECT
	segmento,
	mes::date,
	TO_CHAR(mes, 'Mon-YY') AS mes_abrev,
	total_mrr,
	receita_mes_anterior,
	total_mrr - receita_mes_anterior AS var_mom_abs,
	ROUND((total_mrr - receita_mes_anterior) / NULLIF(receita_mes_anterior,0),2) AS var_mom_pct
FROM mom
ORDER BY mes, total_mrr DESC;

-- 3º) Valor do pedido atual vs média dos últimos 3 (LAG)
WITH pedido_mes AS(
	SELECT
		l.nome AS cliente,
		date_trunc('month', c.data_inicio) as mes,
		SUM(c.mrr) AS valor_pedido
	FROM leads l
	INNER JOIN oportunidades o
		ON l.id = o.lead_id
	INNER JOIN contratos c
		ON o.id = c.oportunidade_id
	WHERE c.data_inicio >= (date_trunc('month', CURRENT_DATE)- INTERVAL '12 months')
	AND c.data_inicio <= CURRENT_DATE
	GROUP BY l.nome, date_trunc('month', c.data_inicio)
),
media_3m AS(
	SELECT
	cliente,
	mes,
	valor_pedido,
	ROUND(
		AVG(valor_pedido) OVER (
		    PARTITION BY cliente
		    ORDER BY mes
		    ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
		),2
	) AS media_mrr_3m
	FROM pedido_mes
)
SELECT
	cliente,
	mes::date,
	TO_CHAR(mes,'mon-yy') AS mes_abrev,
	valor_pedido,
	media_mrr_3m
FROM media_3m
ORDER BY mes, valor_pedido DESC;

-- 4º) Clientes que compraram em Jan mas não em Fev (churn)
WITH pedido_jan_fev AS(
	SELECT
		l.nome AS cliente,
		date_trunc('month', c.data_inicio)::date as mes,
		SUM(c.mrr) AS valor_pedido
	FROM leads l
	INNER JOIN oportunidades o
		ON l.id = o.lead_id
	INNER JOIN contratos c
		ON o.id = c.oportunidade_id
	WHERE date_trunc('month', c.data_inicio) IN ('2026-01-01', '2026-02-01')  
	GROUP BY l.nome, date_trunc('month', c.data_inicio)
)
SELECT DISTINCT jan.cliente
FROM pedido_jan_fev jan
WHERE jan.mes = '2026-01-01'
  AND NOT EXISTS (
      SELECT cliente
      FROM pedido_jan_fev fev
      WHERE fev.cliente = jan.cliente
        AND fev.mes = '2026-02-01'
  )
ORDER BY cliente;