-- =====================================================================
-- schema.sql - Base "Queimadas MG" (focos de calor e unidades de conservação)
-- RGINT de Ipatinga (MG), 2024-2025 | SRID 4674 (SIRGAS 2000)
-- Compatível com PostgreSQL 14+ e PostGIS 3.x
--
-- Uso (a partir da raiz do repositório):
--   psql -d queimadas_mg -f sql/schema.sql
-- O script pode ser executado de novo: ele apaga e recria as tabelas.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- Ordem inversa das FKs
DROP TABLE IF EXISTS foco_calor CASCADE;
DROP TABLE IF EXISTS unidade_conservacao CASCADE;
DROP TABLE IF EXISTS categoria_uc CASCADE;
DROP TABLE IF EXISTS municipio CASCADE;

-- ---------------------------------------------------------------------
-- municipio (MultiPolygon, 4674)
-- ---------------------------------------------------------------------
CREATE TABLE municipio (
    cod_ibge  integer       PRIMARY KEY,
    nome      varchar(100)  NOT NULL,
    uf        char(2)       NOT NULL,
    cod_rgi   char(6)       NOT NULL,
    nome_rgi  varchar(100)  NOT NULL,
    area_km2  numeric(12,3) NOT NULL,
    geom      geometry(MultiPolygon, 4674) NOT NULL,
    CONSTRAINT ck_municipio_cod_ibge CHECK (cod_ibge BETWEEN 1000000 AND 9999999),
    CONSTRAINT ck_municipio_uf       CHECK (uf ~ '^[A-Z]{2}$'),
    CONSTRAINT ck_municipio_area     CHECK (area_km2 >= 0),
    CONSTRAINT ck_municipio_geom     CHECK (ST_IsValid(geom))
);

-- ---------------------------------------------------------------------
-- categoria_uc (tabela de domínio, sem geometria)
-- ---------------------------------------------------------------------
CREATE TABLE categoria_uc (
    cod_categoria smallint    PRIMARY KEY,
    descricao     varchar(60) NOT NULL,
    grupo         varchar(20) NOT NULL,
    CONSTRAINT uq_categoria_uc_descricao UNIQUE (descricao),
    CONSTRAINT ck_categoria_uc_grupo
        CHECK (grupo IN ('PROTECAO_INTEGRAL', 'USO_SUSTENTAVEL'))
);

-- ---------------------------------------------------------------------
-- unidade_conservacao (MultiPolygon, 4674)
-- ---------------------------------------------------------------------
CREATE TABLE unidade_conservacao (
    id_uc              integer       PRIMARY KEY,   -- uc_id do CNUC
    cod_cnuc           varchar(12)   NOT NULL,
    nome               varchar(150)  NOT NULL,
    cod_categoria      smallint      NOT NULL,
    esfera             varchar(10)   NOT NULL,
    data_cadastro      date,
    ato_criacao        varchar(254),
    area_ha_ato        numeric(12,2),
    area_ha_poligono   numeric(12,2),
    qualidade_poligono varchar(254),
    plano_manejo       varchar(15),
    geom               geometry(MultiPolygon, 4674) NOT NULL,
    CONSTRAINT uq_uc_cod_cnuc UNIQUE (cod_cnuc),
    CONSTRAINT fk_uc_categoria FOREIGN KEY (cod_categoria)
        REFERENCES categoria_uc (cod_categoria),
    CONSTRAINT ck_uc_esfera
        CHECK (esfera IN ('FEDERAL', 'ESTADUAL', 'MUNICIPAL')),
    CONSTRAINT ck_uc_area_ato      CHECK (area_ha_ato >= 0),
    CONSTRAINT ck_uc_area_poligono CHECK (area_ha_poligono >= 0),
    CONSTRAINT ck_uc_plano_manejo
        CHECK (plano_manejo IN ('SIM', 'NAO', 'SEM_INFORMACAO')),
    CONSTRAINT ck_uc_geom CHECK (ST_IsValid(geom))
);

-- ---------------------------------------------------------------------
-- foco_calor (Point, 4674)
-- id_foco é gerado pelo banco (não está no CSV)
-- ---------------------------------------------------------------------
CREATE TABLE foco_calor (
    id_foco        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    foco_id_inpe   varchar(36)  NOT NULL,
    data_hora_gmt  timestamp    NOT NULL,
    bioma          varchar(30),
    cod_ibge       integer      NOT NULL,
    id_uc          integer,                         -- nulo = fora de UC
    municipio_inpe varchar(100),
    geom           geometry(Point, 4674) NOT NULL,
    CONSTRAINT uq_foco_id_inpe UNIQUE (foco_id_inpe),
    CONSTRAINT fk_foco_municipio FOREIGN KEY (cod_ibge)
        REFERENCES municipio (cod_ibge),
    CONSTRAINT fk_foco_uc FOREIGN KEY (id_uc)
        REFERENCES unidade_conservacao (id_uc),
    CONSTRAINT ck_foco_periodo
        CHECK (data_hora_gmt >= '2024-01-01' AND data_hora_gmt < '2026-01-01'),
    CONSTRAINT ck_foco_geom CHECK (ST_IsValid(geom))
);

-- ---------------------------------------------------------------------
-- Índices espaciais (GiST)
-- ---------------------------------------------------------------------
CREATE INDEX idx_municipio_geom           ON municipio           USING GIST (geom);
CREATE INDEX idx_unidade_conservacao_geom ON unidade_conservacao USING GIST (geom);
CREATE INDEX idx_foco_calor_geom          ON foco_calor          USING GIST (geom);

-- Índices B-tree auxiliares (consultas por município, UC e data)
CREATE INDEX idx_foco_calor_cod_ibge ON foco_calor (cod_ibge);
CREATE INDEX idx_foco_calor_id_uc    ON foco_calor (id_uc);
CREATE INDEX idx_foco_calor_data     ON foco_calor (data_hora_gmt);
CREATE INDEX idx_uc_cod_categoria    ON unidade_conservacao (cod_categoria);

-- ---------------------------------------------------------------------
-- Comentários (documentação dentro do banco)
-- ---------------------------------------------------------------------
COMMENT ON TABLE municipio IS 'Municípios da RGINT de Ipatinga (MG). Fonte: IBGE, Malha Municipal 2025.';
COMMENT ON COLUMN municipio.cod_ibge IS 'Código do município no IBGE (7 dígitos).';
COMMENT ON COLUMN municipio.nome     IS 'Nome oficial do município.';
COMMENT ON COLUMN municipio.uf       IS 'Sigla da unidade da federação.';
COMMENT ON COLUMN municipio.cod_rgi  IS 'Código da Região Geográfica Imediata (IBGE).';
COMMENT ON COLUMN municipio.nome_rgi IS 'Nome da Região Geográfica Imediata.';
COMMENT ON COLUMN municipio.area_km2 IS 'Área territorial em km², conforme a malha do IBGE.';
COMMENT ON COLUMN municipio.geom     IS 'Limite municipal (MultiPolygon, SIRGAS 2000).';

COMMENT ON TABLE categoria_uc IS 'Tabela de domínio: categorias de unidade de conservação e grupo (SNUC).';
COMMENT ON COLUMN categoria_uc.cod_categoria IS 'Código da categoria (interno desta base).';
COMMENT ON COLUMN categoria_uc.descricao     IS 'Descrição da categoria.';
COMMENT ON COLUMN categoria_uc.grupo         IS 'PROTECAO_INTEGRAL ou USO_SUSTENTAVEL.';

COMMENT ON TABLE unidade_conservacao IS 'UCs com pelo menos 50% da área na RGINT de Ipatinga. Fonte: MMA, CNUC 2025_08.';
COMMENT ON COLUMN unidade_conservacao.id_uc              IS 'Identificador da UC (uc_id do CNUC).';
COMMENT ON COLUMN unidade_conservacao.cod_cnuc           IS 'Código CNUC da UC.';
COMMENT ON COLUMN unidade_conservacao.nome               IS 'Nome da UC.';
COMMENT ON COLUMN unidade_conservacao.cod_categoria      IS 'Categoria da UC. Referencia categoria_uc.';
COMMENT ON COLUMN unidade_conservacao.esfera             IS 'Esfera administrativa: FEDERAL, ESTADUAL ou MUNICIPAL.';
COMMENT ON COLUMN unidade_conservacao.data_cadastro      IS 'Data derivada de cria_ano do CNUC; nem sempre coincide com o ato de criação.';
COMMENT ON COLUMN unidade_conservacao.ato_criacao        IS 'Ato legal de criação (texto do CNUC, truncado em 254 bytes).';
COMMENT ON COLUMN unidade_conservacao.area_ha_ato        IS 'Área em hectares conforme o ato de criação.';
COMMENT ON COLUMN unidade_conservacao.area_ha_poligono   IS 'Área em hectares calculada sobre o polígono.';
COMMENT ON COLUMN unidade_conservacao.qualidade_poligono IS 'Qualidade/origem do polígono (texto do CNUC).';
COMMENT ON COLUMN unidade_conservacao.plano_manejo       IS 'Existência de plano de manejo: SIM, NAO ou SEM_INFORMACAO.';
COMMENT ON COLUMN unidade_conservacao.geom               IS 'Limite da UC (MultiPolygon, SIRGAS 2000).';

COMMENT ON TABLE foco_calor IS 'Focos de calor do satélite de referência do INPE, 2024-2025, na RGINT de Ipatinga.';
COMMENT ON COLUMN foco_calor.id_foco        IS 'Identificador interno, gerado pelo banco.';
COMMENT ON COLUMN foco_calor.foco_id_inpe   IS 'Identificador (UUID) do foco no INPE.';
COMMENT ON COLUMN foco_calor.data_hora_gmt  IS 'Data e hora da passagem do satélite (GMT).';
COMMENT ON COLUMN foco_calor.bioma          IS 'Bioma informado pelo INPE.';
COMMENT ON COLUMN foco_calor.cod_ibge       IS 'Município onde o foco cai (ST_Within). Referencia municipio.';
COMMENT ON COLUMN foco_calor.id_uc          IS 'UC que contém o foco (ST_Within); nulo = fora de UC. Referencia unidade_conservacao.';
COMMENT ON COLUMN foco_calor.municipio_inpe IS 'Nome do município conforme o INPE (pode diferir na grafia do IBGE).';
COMMENT ON COLUMN foco_calor.geom           IS 'Localização do foco (Point, SIRGAS 2000; reprojetado de EPSG:4326).';