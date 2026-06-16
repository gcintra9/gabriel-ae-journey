SELECT
    p.data_pedido,
    p.cliente_id,
    p.valor,
    c.segmento
FROM pedidos p
INNER JOIN clientes c
	ON p.cliente_id = c.cliente_id
INNER JOIN (
	SELECT cliente_id
	FROM pedidos
	WHERE data_pedido >= '2024-01-01' AND data_pedido < '2025-01-01'
	GROUP BY cliente_id
	HAVING AVG(valor) > 500
) x
	ON p.cliente_id = x.cliente_id
WHERE
	data_pedido >= '2024-01-01' AND data_pedido < '2025-01-01'
	AND c.segmento = 'premium'
ORDER BY p.valor DESC;