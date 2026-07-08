# Case SQL 02 → Otimização de Query

**Objetivo:** Identificar problemas de performance em uma query problemática, reescrever de forma eficiente e documentar a estratégia de indexação.

\---

## Query original (problemática)

```sql
SELECT \*
FROM pedidos p
WHERE YEAR(data\_pedido) = 2024
  AND (SELECT AVG(valor) FROM pedidos) > 500
  AND cliente\_id IN (
    SELECT cliente\_id FROM clientes
    WHERE segmento = 'premium'
  )
ORDER BY valor DESC;
```

\---

## Problemas identificados

### 1\. Função na coluna WHERE: `YEAR(data\_pedido)`

Aplicar uma função diretamente sobre a coluna no `WHERE` impede o uso de índice,
forçando um **full scan** da tabela antes de qualquer filtro.

**Correção:** substituir por range explícito de datas.

```sql
-- ❌ Antes
WHERE YEAR(data\_pedido) = 2024

-- ✅ Depois
WHERE data\_pedido >= '2024-01-01' AND data\_pedido < '2025-01-01'
```

\---

### 2\. Subquery escalar constante no WHERE

`(SELECT AVG(valor) FROM pedidos) > 500` calcula a média **global** de toda a tabela
e compara com 500 linha por linha a cada execução, independente dos filtros do `WHERE`.
O problema semântico é que a intenção era filtrar **clientes** cuja média de valor fosse
maior que 500, não comparar a média global como condição booleana.

**Correção:** mover para `HAVING` dentro de uma subquery agrupada por cliente.

```sql
-- ❌ Antes
AND (SELECT AVG(valor) FROM pedidos) > 500

-- ✅ Depois
INNER JOIN (
    SELECT cliente\_id
    FROM pedidos
    WHERE data\_pedido >= '2024-01-01' AND data\_pedido < '2025-01-01'
    GROUP BY cliente\_id
    HAVING AVG(valor) > 500
) x ON p.cliente\_id = x.cliente\_id
```

\---

### 3\. Subquery no `IN` em vez de `JOIN`

```sql
cliente\_id IN (SELECT cliente\_id FROM clientes WHERE segmento = 'premium')
```

O `IN` com subquery força uma pesquisa na tabela clientes para cada linha de pedidos.
Um `INNER JOIN` resolve o mesmo problema de forma mais eficiente e legível.

**Correção:** substituir por `INNER JOIN`.

```sql
-- ❌ Antes
AND cliente\_id IN (SELECT cliente\_id FROM clientes WHERE segmento = 'premium')

-- ✅ Depois
INNER JOIN clientes c ON p.cliente\_id = c.cliente\_id
WHERE c.segmento = 'premium'
```

\---

### 4\. `SELECT \*` retornando todas as colunas

Retornar todas as colunas tem custo desnecessário de I/O e torna o código
menos legível e mais frágil a mudanças de schema.

**Correção:** listar apenas as colunas necessárias.

```sql
-- ❌ Antes
SELECT \*

-- ✅ Depois
SELECT
    p.data\_pedido,
    p.cliente\_id,
    p.valor,
    c.segmento
```

\---

## Query reescrita

```sql
SELECT
    p.data\_pedido,
    p.cliente\_id,
    p.valor,
    c.segmento
FROM pedidos p
INNER JOIN clientes c
    ON p.cliente\_id = c.cliente\_id
INNER JOIN (
    SELECT cliente\_id
    FROM pedidos
    WHERE data\_pedido >= '2024-01-01'
      AND data\_pedido < '2025-01-01'
    GROUP BY cliente\_id
    HAVING AVG(valor) > 500
) x ON p.cliente\_id = x.cliente\_id
WHERE p.data\_pedido >= '2024-01-01'
  AND p.data\_pedido < '2025-01-01'
  AND c.segmento = 'premium'
ORDER BY p.valor DESC;
```

\---

## Índices sugeridos

```sql
-- Índice composto na tabela fato, cobre o filtro de range e o JOIN
CREATE INDEX idx\_pedidos\_data\_cliente
ON pedidos(data\_pedido, cliente\_id);

-- Índice auxiliar na dimensão, cobre o filtro de segmento
CREATE INDEX idx\_clientes\_segmento
ON clientes(segmento);
```

**Justificativa:**

* `data\_pedido` é o campo de maior seletividade e granularidade, filtro de range que reduz
drasticamente o volume de linhas processadas. Vai primeiro no índice composto.
* `cliente\_id` aparece nos JOINs, incluir no índice composto evita lookup adicional.
* `segmento` em `clientes` cobre o filtro do JOIN e evita full scan na dimensão.
* A **ordem do índice composto importa**: campo de range sempre antes do campo de igualdade.

\---

## EXPLAIN ANALYZE → o que verificar

Antes de qualquer otimização, rodar:

```sql
EXPLAIN ANALYZE
SELECT \* FROM pedidos p
WHERE YEAR(data\_pedido) = 2024
...
```

### Nós críticos para observar

|Nó|Query original|Esperado após otimização|
|-|-|-|
|**Seq Scan**|Presente → percorre a tabela inteira|`Index Scan` ou `Bitmap Index Scan`|
|**Rows Removed by Filter**|Alto → processa e descarta a maioria das linhas|Reduzido significativamente|
|**Sort**|Sort em memória ou disco|`Index Scan ordered` (sem sort explícito)|
|**Nested Loop**|Custo alto por subquery no IN|Custo reduzido com JOIN direto|

### Interpretação prática

* **Seq Scan → Index Scan:** confirma que o índice está sendo usado após a criação
* **Rows Removed alto:** sinal de que a função `YEAR()` estava forçando varredura completa
* **Sort desaparecendo:** o índice em `data\_pedido` pode eliminar o passo de ordenação
* **Cost= caindo:** comparar o valor de `cost=` antes e depois é a métrica objetiva da melhoria

\---

## Tecnologias

* PostgreSQL
* SQL — JOINs, HAVING, subqueries, índices compostos
* EXPLAIN ANALYZE

