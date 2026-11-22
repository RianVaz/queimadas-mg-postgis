-- =====================================================================
-- dados.sql - Carga dos CSVs tratados (dados/tratados/)
--
-- IMPORTANTE: execute o psql a partir da RAIZ do repositório, pois os
-- caminhos abaixo são relativos:
--   psql -d queimadas_mg -f sql/dados.sql
--
-- Cada \copy precisa ficar em UMA linha só (limitação do psql).
-- A geometria vem em EWKT (SRID=4674;...), convertida pelo PostGIS.
-- Valores vazios no CSV viram NULL.
-- =====================================================================

\set ON_ERROR_STOP on

-- Ordem das FKs: municipio -> categoria_uc -> unidade_conservacao -> foco_calor
\copy municipio (cod_ibge, nome, uf, cod_rgi, nome_rgi, area_km2, geom) FROM 'dados/tratados/municipio.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

\copy categoria_uc (cod_categoria, descricao, grupo) FROM 'dados/tratados/categoria_uc.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

\copy unidade_conservacao (id_uc, cod_cnuc, nome, cod_categoria, esfera, data_cadastro, ato_criacao, area_ha_ato, area_ha_poligono, qualidade_poligono, plano_manejo, geom) FROM 'dados/tratados/unidade_conservacao.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

\copy foco_calor (foco_id_inpe, data_hora_gmt, bioma, cod_ibge, id_uc, municipio_inpe, geom) FROM 'dados/tratados/foco_calor.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

ANALYZE;

-- Conferência rápida (esperado: 44 / 4 / 13 / 624)
SELECT 'municipio' AS tabela, count(*) AS registros FROM municipio
UNION ALL SELECT 'categoria_uc',        count(*) FROM categoria_uc
UNION ALL SELECT 'unidade_conservacao', count(*) FROM unidade_conservacao
UNION ALL SELECT 'foco_calor',          count(*) FROM foco_calor;