TRUNCATE TABLE staging.ST_VENDEDOR

INSERT INTO staging.ST_VENDEDOR
(
  vendedor
, squad
)
SELECT DISTINCT
	  vendedor
	, squad
FROM
	public.oportunidades
WHERE vendedor IS NOT NULL;