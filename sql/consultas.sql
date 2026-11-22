-- =====================================================================
-- Base "Queimadas MG" - consultas de verificação e de análise
-- Disciplina: CSI803 - Banco de Dados Geográficos (UFOP)
--
-- Pré-requisito: schema.sql e dados.sql já executados no banco.
-- Execução (a partir da raiz do repositório):
--   psql -d queimadas_mg -f sql/consultas.sql
-- Também pode ser rodado consulta por consulta no pgAdmin ou no QGIS.
--
-- SRID das tabelas: 4674 (SIRGAS 2000). Medidas em metros usam
-- ::geography (o resultado de ST_Area/ST_DWithin vem em m² / m).
-- =====================================================================


-- =====================================================================
-- PARTE 1 - VERIFICAÇÃO DA CARGA
-- =====================================================================

-- 1.1 Contagem de registros por tabela.
-- Esperado: municipio = 44, categoria_uc = 4, unidade_conservacao = 13,
-- foco_calor = 624 (total das tabelas espaciais = 681).
SELECT 'municipio' AS tabela, count(*) AS registros FROM municipio
UNION ALL
SELECT 'categoria_uc', count(*) FROM categoria_uc
UNION ALL
SELECT 'unidade_conservacao', count(*) FROM unidade_conservacao
UNION ALL
SELECT 'foco_calor', count(*) FROM foco_calor
ORDER BY tabela;

-- 1.2 Total de feições nas tabelas espaciais (esperado: 681; mínimo
-- exigido pelo enunciado: 500).
SELECT (SELECT count(*) FROM municipio)
     + (SELECT count(*) FROM unidade_conservacao)
     + (SELECT count(*) FROM foco_calor) AS total_feicoes;

-- 1.3 Geometrias nulas, vazias ou inválidas em cada tabela.
-- Esperado: 0 em todas as linhas.
SELECT 'municipio' AS tabela, count(*) AS problemas
FROM municipio
WHERE geom IS NULL OR ST_IsEmpty(geom) OR NOT ST_IsValid(geom)
UNION ALL
SELECT 'unidade_conservacao', count(*)
FROM unidade_conservacao
WHERE geom IS NULL OR ST_IsEmpty(geom) OR NOT ST_IsValid(geom)
UNION ALL
SELECT 'foco_calor', count(*)
FROM foco_calor
WHERE geom IS NULL OR ST_IsEmpty(geom) OR NOT ST_IsValid(geom);

-- 1.4 Tipo geométrico e SRID declarados em cada coluna de geometria.
-- Esperado: MultiPolygon/4674 (municipio e unidade_conservacao) e
-- Point/4674 (foco_calor).
SELECT f_table_name AS tabela,
       f_geometry_column AS coluna,
       type AS tipo_geometrico,
       srid
FROM geometry_columns
WHERE f_table_schema = 'public'
  AND f_table_name IN ('municipio', 'unidade_conservacao', 'foco_calor')
ORDER BY f_table_name;

-- 1.5 SRID e tipo efetivamente gravados nas geometrias (confere com 1.4).
SELECT 'municipio' AS tabela,
       array_agg(DISTINCT ST_SRID(geom)) AS srids,
       array_agg(DISTINCT GeometryType(geom)) AS tipos
FROM municipio
UNION ALL
SELECT 'unidade_conservacao',
       array_agg(DISTINCT ST_SRID(geom)),
       array_agg(DISTINCT GeometryType(geom))
FROM unidade_conservacao
UNION ALL
SELECT 'foco_calor',
       array_agg(DISTINCT ST_SRID(geom)),
       array_agg(DISTINCT GeometryType(geom))
FROM foco_calor;

-- 1.6 Consistência de foco_calor.cod_ibge com a relação espacial
-- ST_Within(foco, município). Esperado: 0 divergências.
SELECT count(*) AS divergencias_municipio
FROM foco_calor f
JOIN municipio m ON ST_Within(f.geom, m.geom)
WHERE f.cod_ibge <> m.cod_ibge;

-- 1.7 Focos que não caem dentro de nenhum município (ex.: ponto sobre a
-- divisa). Esperado: 0.
SELECT count(*) AS focos_fora_de_municipios
FROM foco_calor f
WHERE NOT EXISTS (
    SELECT 1 FROM municipio m WHERE ST_Within(f.geom, m.geom)
);

-- 1.8 Consistência de foco_calor.id_uc com ST_Within(foco, UC).
-- (a) focos com id_uc preenchido que não estão dentro dessa UC;
-- (b) focos dentro de alguma UC, mas com id_uc nulo.
-- Esperado: 0 nas duas.
SELECT count(*) AS a_id_uc_sem_estar_dentro
FROM foco_calor f
JOIN unidade_conservacao u ON u.id_uc = f.id_uc
WHERE NOT ST_Within(f.geom, u.geom);

SELECT count(*) AS b_dentro_de_uc_com_id_uc_nulo
FROM foco_calor f
WHERE f.id_uc IS NULL
  AND EXISTS (
      SELECT 1 FROM unidade_conservacao u WHERE ST_Within(f.geom, u.geom)
  );


-- =====================================================================
-- PARTE 2 - EXEMPLOS DE ANÁLISE
-- Pergunta geral da base: quanto fogo ocorre dentro e no entorno das
-- áreas protegidas da região, por município e ao longo do tempo?
-- =====================================================================

-- 2.1 Focos por município, do maior para o menor.
-- Pergunta: quais municípios concentraram mais focos de calor em
-- 2024-2025? (LEFT JOIN mantém municípios com zero focos.)
SELECT m.cod_ibge,
       m.nome AS municipio,
       count(f.id_foco) AS total_focos
FROM municipio m
LEFT JOIN foco_calor f ON f.cod_ibge = m.cod_ibge
GROUP BY m.cod_ibge, m.nome
ORDER BY total_focos DESC, m.nome;

-- 2.2 Focos por ano.
-- Pergunta: 2024 teve mais focos que 2025? (esperado: 454 e 170)
SELECT EXTRACT(YEAR FROM data_hora_gmt)::int AS ano,
       count(*) AS total_focos
FROM foco_calor
GROUP BY ano
ORDER BY ano;

-- 2.3 Focos por ano e mês.
-- Pergunta: em quais meses ocorre a temporada de fogo na região?
SELECT EXTRACT(YEAR FROM data_hora_gmt)::int AS ano,
       EXTRACT(MONTH FROM data_hora_gmt)::int AS mes,
       count(*) AS total_focos
FROM foco_calor
GROUP BY ano, mes
ORDER BY ano, mes;

-- 2.4 Focos dentro de cada unidade de conservação, de duas formas:
-- pela chave estrangeira (foco_calor.id_uc) e pela relação espacial
-- (ST_Within). As duas colunas devem coincidir (coluna "confere").
-- Pergunta: quais UCs registraram focos em seu interior?
WITH por_fk AS (
    SELECT id_uc, count(*) AS n
    FROM foco_calor
    WHERE id_uc IS NOT NULL
    GROUP BY id_uc
),
por_geom AS (
    SELECT u.id_uc, count(*) AS n
    FROM unidade_conservacao u
    JOIN foco_calor f ON ST_Within(f.geom, u.geom)
    GROUP BY u.id_uc
)
SELECT u.id_uc,
       u.nome AS unidade_conservacao,
       COALESCE(fk.n, 0) AS focos_por_fk,
       COALESCE(g.n, 0) AS focos_por_st_within,
       COALESCE(fk.n, 0) = COALESCE(g.n, 0) AS confere
FROM unidade_conservacao u
LEFT JOIN por_fk fk ON fk.id_uc = u.id_uc
LEFT JOIN por_geom g ON g.id_uc = u.id_uc
ORDER BY focos_por_fk DESC, u.nome;

-- 2.5 Focos dentro e fora de UCs (esperado: 27 dentro e 597 fora).
-- Pergunta: que fração dos focos da região ocorre em áreas protegidas?
SELECT count(*) FILTER (WHERE id_uc IS NOT NULL) AS dentro_de_uc,
       count(*) FILTER (WHERE id_uc IS NULL) AS fora_de_uc,
       round(100.0 * count(*) FILTER (WHERE id_uc IS NOT NULL) / count(*), 2)
           AS percentual_dentro_de_uc
FROM foco_calor;

-- 2.6 Focos em UCs de proteção integral x uso sustentável
-- (junção com a tabela de domínio categoria_uc).
-- Pergunta: o fogo atinge mais as UCs de proteção integral ou as de uso
-- sustentável (APA, Floresta, RPPN)?
SELECT c.grupo,
       c.descricao AS categoria,
       count(DISTINCT u.id_uc) AS qtd_ucs,
       count(f.id_foco) AS focos_dentro
FROM categoria_uc c
LEFT JOIN unidade_conservacao u ON u.cod_categoria = c.cod_categoria
LEFT JOIN foco_calor f ON f.id_uc = u.id_uc
GROUP BY c.grupo, c.descricao
ORDER BY c.grupo, focos_dentro DESC;

-- 2.7 Focos no entorno de 5 km de cada UC, separando os que estão dentro
-- da UC dos que estão fora dela (a até 5 km do limite).
-- Pergunta: o fogo no entorno das UCs é maior que dentro delas?
-- Observação: ::geography faz o cálculo em metros, mas não usa o índice
-- GiST da coluna geom. Com 13 UCs e 624 focos o custo é desprezível.
SELECT u.id_uc,
       u.nome AS unidade_conservacao,
       count(f.id_foco) FILTER (WHERE ST_Within(f.geom, u.geom))
           AS focos_dentro,
       count(f.id_foco) FILTER (WHERE NOT ST_Within(f.geom, u.geom))
           AS focos_entorno_5km
FROM unidade_conservacao u
LEFT JOIN foco_calor f
       ON ST_DWithin(f.geom::geography, u.geom::geography, 5000)
GROUP BY u.id_uc, u.nome
ORDER BY focos_entorno_5km DESC, u.nome;

-- 2.8 Densidade de focos por 100 km² em cada município.
-- Pergunta: quais municípios têm mais fogo em relação ao seu tamanho?
-- (usa a coluna area_km2 e evita viés de municípios muito grandes)
SELECT m.cod_ibge,
       m.nome AS municipio,
       m.area_km2,
       count(f.id_foco) AS total_focos,
       round(count(f.id_foco)::numeric / NULLIF(m.area_km2, 0) * 100, 3)
           AS focos_por_100km2
FROM municipio m
LEFT JOIN foco_calor f ON f.cod_ibge = m.cod_ibge
GROUP BY m.cod_ibge, m.nome, m.area_km2
ORDER BY focos_por_100km2 DESC NULLS LAST, m.nome;

-- 2.9 Unidades de conservação e os municípios que elas abrangem
-- (relação N:N por ST_Intersects), com a área de interseção em hectares.
-- Pergunta: em quais municípios cada UC está localizada e quanto de sua
-- área cai em cada um?
-- Observações: (a) o subselect descarta interseções de área zero (UC que
-- apenas toca a divisa do município); (b) as UCs foram mantidas com o
-- polígono completo, então a soma das interseções pode ser menor que a
-- área da UC quando parte dela fica fora dos 44 municípios da região.
SELECT t.id_uc,
       t.unidade_conservacao,
       t.cod_ibge,
       t.municipio,
       t.area_intersecao_ha
FROM (
    SELECT u.id_uc,
           u.nome AS unidade_conservacao,
           m.cod_ibge,
           m.nome AS municipio,
           round((ST_Area(ST_Intersection(u.geom, m.geom)::geography)
                  / 10000)::numeric, 2) AS area_intersecao_ha
    FROM unidade_conservacao u
    JOIN municipio m ON ST_Intersects(u.geom, m.geom)
) t
WHERE t.area_intersecao_ha > 0
ORDER BY t.unidade_conservacao, t.area_intersecao_ha DESC;
