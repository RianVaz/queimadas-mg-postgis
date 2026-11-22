"""Tratamento dos dados brutos para importação no PostGIS.

Lê os arquivos originais de dados/brutos/, aplica limpeza, padronização,
reprojeção e validação, e grava em dados/tratados/:

    municipio.csv
    categoria_uc.csv
    unidade_conservacao.csv
    foco_calor.csv
    log_tratamento.txt

As geometrias são gravadas em EWKT (SRID=4674;...), prontas para \\copy.

Uso (a partir da raiz do repositório):
    python scripts/tratamento.py
"""
from pathlib import Path

import geopandas as gpd
import pandas as pd
import shapely
import re
from shapely.geometry import MultiPolygon, Polygon
from unidecode import unidecode

# ---------------------------------------------------------------------------
# Parâmetros
# ---------------------------------------------------------------------------
BRUTOS = Path("dados/brutos")
TRATADOS = Path("dados/tratados")

COD_RGINT = "3105"            # Região Geográfica Intermediária de Ipatinga
SRID = 4674                   # SIRGAS 2000
SRID_METRICO = 31983          # SIRGAS 2000 / UTM 23S (só para cálculo de áreas)
PCT_MIN_UC = 50.0             # % mínima da área da UC dentro da região
DATA_INI = "2024-01-01"
DATA_FIM = "2025-12-31 23:59:59"
PRECISAO_WKT = 7              # casas decimais nas coordenadas (~1 cm)

MUN_ZIP = f"zip://{BRUTOS}/MG_Municipios_2025.zip"
CNUC_SHP = f"zip://{BRUTOS}/shp_cnuc_2025_08.zip!cnuc_2025_08.shp"
FOCOS_ZIPS = [BRUTOS / "focos_br_ref_2024.zip", BRUTOS / "focos_br_ref_2025.zip"]

TRATADOS.mkdir(parents=True, exist_ok=True)
_log_linhas = []


def log(msg=""):
    """Mostra a mensagem na tela e guarda para o arquivo de log."""
    print(msg)
    _log_linhas.append(str(msg))


# ---------------------------------------------------------------------------
# Funções auxiliares
# ---------------------------------------------------------------------------
def ler_shp_utf8(caminho):
    """Lê shapefile UTF-8 com textos truncados no meio de um caractere.

    O DBF limita campos de texto a 254 bytes; no CNUC alguns textos foram
    cortados no meio de um caractere acentuado. Lê-se em latin1 (aceita
    qualquer byte) e converte-se de volta para UTF-8, descartando o byte
    incompleto.
    """
    gdf = gpd.read_file(caminho, encoding="latin1")
    for col in gdf.columns:
        if col == "geometry":
            continue
        gdf[col] = gdf[col].map(
            lambda v: v.encode("latin1").decode("utf-8", errors="ignore")
            if isinstance(v, str) else v
        )
    return gdf


def limpar_texto(serie):
    """Remove espaços nas pontas e espaços repetidos; vazio vira nulo."""
    s = serie.astype("string").str.strip().str.replace(r"\s+", " ", regex=True)
    return s.replace("", pd.NA)


def para_codigo(valor):
    """'Proteção Integral' -> 'PROTECAO_INTEGRAL'."""
    if pd.isna(valor):
        return pd.NA
    return unidecode(str(valor)).strip().upper().replace(" ", "_")


def para_multipolygon(geom):
    """Converte Polygon/GeometryCollection em MultiPolygon (só partes de área)."""
    if geom is None or geom.is_empty:
        return None
    if isinstance(geom, MultiPolygon):
        return geom
    if isinstance(geom, Polygon):
        return MultiPolygon([geom])
    partes = []
    for g in getattr(geom, "geoms", []):
        if isinstance(g, Polygon):
            partes.append(g)
        elif isinstance(g, MultiPolygon):
            partes.extend(g.geoms)
    return MultiPolygon(partes) if partes else None


def corrigir_poligonos(gdf, nome):
    """make_valid + conversão para MultiPolygon, registrando correções."""
    invalidas = int((~gdf.is_valid).sum())
    gdf = gdf.copy()
    gdf["geometry"] = gdf.make_valid().apply(para_multipolygon)
    log(f"  {nome}: {invalidas} geometria(s) inválida(s) corrigida(s) com make_valid")
    return gdf


def validar(gdf, nome, tipo_esperado):
    """Confere SRID, tipo, validade, vazios e nulos. Interrompe se falhar."""
    problemas = []
    if gdf.crs is None or gdf.crs.to_epsg() != SRID:
        problemas.append(f"SRID diferente de {SRID}: {gdf.crs}")
    if gdf.geometry.isna().any():
        problemas.append(f"{int(gdf.geometry.isna().sum())} geometria(s) nula(s)")
    if gdf.is_empty.any():
        problemas.append(f"{int(gdf.is_empty.sum())} geometria(s) vazia(s)")
    if (~gdf.is_valid).any():
        problemas.append(f"{int((~gdf.is_valid).sum())} geometria(s) inválida(s)")
    tipos = set(gdf.geom_type.unique())
    if tipos != {tipo_esperado}:
        problemas.append(f"tipos encontrados {tipos}, esperado {tipo_esperado}")
    if problemas:
        raise ValueError(f"Validação de {nome} falhou: " + "; ".join(problemas))
    log(f"  {nome}: {len(gdf)} registros, {tipo_esperado}, SRID {SRID}, "
        "todas as geometrias válidas, não vazias e não nulas")


def salvar_csv(gdf, colunas, arquivo):
    """Grava CSV com a geometria em EWKT na última coluna."""
    df = pd.DataFrame(gdf[[c for c in colunas if c != "geometry"]]).copy()
    if "geometry" in colunas:
        wkt = shapely.to_wkt(gdf.geometry.values, rounding_precision=PRECISAO_WKT)
        df["geom"] = [f"SRID={SRID};{w}" for w in wkt]
    caminho = TRATADOS / arquivo
    df.to_csv(caminho, index=False, encoding="utf-8")
    tamanho = caminho.stat().st_size / 1024 / 1024
    log(f"  {caminho} ({len(df)} linhas, {tamanho:.1f} MB)")


# ---------------------------------------------------------------------------
# 1. Municípios
# ---------------------------------------------------------------------------
log("=" * 70)
log("1. MUNICÍPIOS")
log("=" * 70)
mun_br = gpd.read_file(MUN_ZIP)
log(f"  Lidos: {len(mun_br)} municípios de MG (SRC {mun_br.crs})")

mun = mun_br[mun_br["CD_RGINT"] == COD_RGINT].copy()
log(f"  Filtro CD_RGINT = '{COD_RGINT}': {len(mun)} municípios")

mun = mun.to_crs(SRID)
mun = corrigir_poligonos(mun, "municipio")

mun["cod_ibge"] = mun["CD_MUN"].astype(int)
mun["nome"] = limpar_texto(mun["NM_MUN"])
mun["uf"] = limpar_texto(mun["SIGLA_UF"])
mun["cod_rgi"] = limpar_texto(mun["CD_RGI"])
mun["nome_rgi"] = limpar_texto(mun["NM_RGI"])
mun["area_km2"] = pd.to_numeric(mun["AREA_KM2"]).round(3)
mun = mun.sort_values("cod_ibge").reset_index(drop=True)

validar(mun, "municipio", "MultiPolygon")
assert mun["cod_ibge"].is_unique, "cod_ibge repetido"

# Limite da região (usado para filtrar UCs e focos)
limite = mun.dissolve().geometry.iloc[0]
limite_m = gpd.GeoSeries([limite], crs=SRID).to_crs(SRID_METRICO).iloc[0]

# ---------------------------------------------------------------------------
# 2. Unidades de conservação
# ---------------------------------------------------------------------------
log()
log("=" * 70)
log("2. UNIDADES DE CONSERVAÇÃO")
log("=" * 70)
ucs_br = ler_shp_utf8(CNUC_SHP)
log(f"  Lidas: {len(ucs_br)} UCs do Brasil (SRC {ucs_br.crs})")

ucs = ucs_br.to_crs(SRID)
ucs = corrigir_poligonos(ucs, "unidade_conservacao (Brasil)")
ucs = ucs[ucs.intersects(limite)].copy()
log(f"  UCs que interceptam a região: {len(ucs)}")

ucs_m = ucs.to_crs(SRID_METRICO)
ucs["pct_dentro"] = (ucs_m.intersection(limite_m).area / ucs_m.area * 100).values
excluidas = ucs[ucs["pct_dentro"] < PCT_MIN_UC]
for _, r in excluidas.iterrows():
    log(f"    excluída: {r['cd_cnuc']} {r['nome_uc']} ({r['pct_dentro']:.1f}% na região)")
ucs = ucs[ucs["pct_dentro"] >= PCT_MIN_UC].copy()
log(f"  Mantidas (>= {PCT_MIN_UC:.0f}% da área na região): {len(ucs)}")

# Tabela de domínio categoria_uc
ucs["categoria"] = limpar_texto(ucs["categoria"])
ucs["grupo_cod"] = ucs["grupo"].map(para_codigo)
cat = (ucs[["categoria", "grupo_cod"]].drop_duplicates()
       .sort_values(["grupo_cod", "categoria"]).reset_index(drop=True))
if cat["categoria"].duplicated().any():
    raise ValueError("Uma mesma categoria aparece com grupos diferentes")
cat["cod_categoria"] = range(1, len(cat) + 1)
cat = cat.rename(columns={"categoria": "descricao", "grupo_cod": "grupo"})
log(f"  Categorias encontradas: {len(cat)}")
for _, r in cat.iterrows():
    log(f"    {r['cod_categoria']} = {r['descricao']} ({r['grupo']})")

# Colunas finais
ucs = ucs.merge(cat[["descricao", "cod_categoria"]],
                left_on="categoria", right_on="descricao", how="left")
ucs = gpd.GeoDataFrame(ucs, geometry="geometry", crs=SRID)
ucs["id_uc"] = ucs["uc_id"].astype(int)
ucs["cod_cnuc"] = limpar_texto(ucs["cd_cnuc"])
ucs["nome"] = limpar_texto(ucs["nome_uc"])
ucs["esfera"] = ucs["esfera"].map(para_codigo)
ucs["data_cadastro"] = pd.to_datetime(
    ucs["cria_ano"], format="%d-%m-%Y", errors="coerce").dt.date
ucs["ato_criacao"] = limpar_texto(ucs["cria_ato"])
ucs["area_ha_ato"] = pd.to_numeric(ucs["ha_ato"], errors="coerce").round(2)
ucs["area_ha_poligono"] = pd.to_numeric(ucs["ha_total"], errors="coerce").round(2)
ucs["qualidade_poligono"] = limpar_texto(ucs["quali_pol"])
ucs["plano_manejo"] = ucs["pl_manejo"].map(para_codigo)
ucs = ucs.sort_values("id_uc").reset_index(drop=True)

sem_data = int(ucs["data_cadastro"].isna().sum())
log(f"  data_cadastro não convertida (ficou nula): {sem_data}")
log(f"  Esferas: {sorted(ucs['esfera'].dropna().unique())}")
log(f"  Plano de manejo: {sorted(ucs['plano_manejo'].dropna().unique())}")

validar(ucs, "unidade_conservacao", "MultiPolygon")
assert ucs["id_uc"].is_unique, "id_uc repetido"
assert ucs["cod_cnuc"].is_unique, "cod_cnuc repetido"

# ---------------------------------------------------------------------------
# 3. Focos de calor
# ---------------------------------------------------------------------------
log()
log("=" * 70)
log("3. FOCOS DE CALOR")
log("=" * 70)
focos = pd.concat([pd.read_csv(z) for z in FOCOS_ZIPS], ignore_index=True)
log(f"  Lidos: {len(focos)} focos do Brasil (2024 + 2025)")

sem_coord = focos["lat"].isna() | focos["lon"].isna()
log(f"  Removidos por falta de coordenada: {int(sem_coord.sum())}")
focos = focos[~sem_coord]

pts = gpd.GeoDataFrame(
    focos, geometry=gpd.points_from_xy(focos["lon"], focos["lat"]), crs=4326
).to_crs(SRID)
log("  Reprojetados de EPSG:4326 para EPSG:4674")

pts = pts[pts.intersects(limite)].copy()
log(f"  Dentro da região: {len(pts)}")

pts["data_hora_gmt"] = pd.to_datetime(pts["data_pas"], errors="coerce")
sem_data = int(pts["data_hora_gmt"].isna().sum())
if sem_data:
    raise ValueError(f"{sem_data} focos com data_pas não reconhecida")
fora = ~pts["data_hora_gmt"].between(DATA_INI, DATA_FIM)
log(f"  Removidos por data fora de 2024–2025: {int(fora.sum())}")
pts = pts[~fora]

pts["foco_id_inpe"] = limpar_texto(pts["foco_id"].astype(str))
dup = pts["foco_id_inpe"].duplicated()
log(f"  Removidos por foco_id repetido: {int(dup.sum())}")
pts = pts[~dup]

pts["bioma"] = limpar_texto(pts["bioma"])
pts["municipio_inpe"] = limpar_texto(pts["municipio"])

# Município por relação espacial (intersects inclui pontos na divisa;
# se cair em dois municípios, fica o primeiro)
j = gpd.sjoin(pts[["geometry"]], mun[["cod_ibge", "nome", "geometry"]],
              predicate="intersects", how="left")
j = j[~j.index.duplicated(keep="first")]
pts["cod_ibge"] = j["cod_ibge"].astype("Int64")
pts["nome_mun_ibge"] = j["nome"]
if pts["cod_ibge"].isna().any():
    raise ValueError("Há focos sem município atribuído")

norm = lambda s: s.fillna("").map(lambda v: re.sub(r"[^A-Z0-9]", "", unidecode(v).upper()))
diverg = norm(pts["municipio_inpe"]) != norm(pts["nome_mun_ibge"])
log(f"  Município do INPE diferente do obtido por ST_Within: {int(diverg.sum())}")
for _, r in pts[diverg].iterrows():
    log(f"    foco {r['foco_id_inpe']}: INPE = {r['municipio_inpe']} | "
        f"IBGE = {r['nome_mun_ibge']}")

# UC por relação espacial; se o foco estiver em duas UCs sobrepostas,
# fica a de menor área (a mais restritiva/específica)
ucs_area = ucs[["id_uc", "geometry"]].copy()
ucs_area["area_m2"] = ucs.to_crs(SRID_METRICO).area.values
j = gpd.sjoin(pts[["geometry"]], ucs_area, predicate="within", how="inner")
sobrepostos = int(j.index.value_counts().gt(1).sum())
j = j.sort_values("area_m2")
j = j[~j.index.duplicated(keep="first")]
pts["id_uc"] = j["id_uc"].reindex(pts.index).astype("Int64")
log(f"  Focos dentro de alguma UC: {int(pts['id_uc'].notna().sum())}")
log(f"  Focos em duas ou mais UCs sobrepostas (atribuída a menor): {sobrepostos}")
log("  Focos por ano: " + ", ".join(
    f"{a} = {n}" for a, n in pts["data_hora_gmt"].dt.year.value_counts()
    .sort_index().items()))
log(f"  Biomas: {sorted(pts['bioma'].dropna().unique())}")

pts = pts.sort_values(["data_hora_gmt", "foco_id_inpe"]).reset_index(drop=True)
validar(pts, "foco_calor", "Point")

# ---------------------------------------------------------------------------
# 4. Gravação
# ---------------------------------------------------------------------------
log()
log("=" * 70)
log("4. ARQUIVOS GRAVADOS")
log("=" * 70)
salvar_csv(mun, ["cod_ibge", "nome", "uf", "cod_rgi", "nome_rgi", "area_km2",
                 "geometry"], "municipio.csv")
cat[["cod_categoria", "descricao", "grupo"]].to_csv(
    TRATADOS / "categoria_uc.csv", index=False, encoding="utf-8")
log(f"  {TRATADOS / 'categoria_uc.csv'} ({len(cat)} linhas)")
salvar_csv(ucs, ["id_uc", "cod_cnuc", "nome", "cod_categoria", "esfera",
                 "data_cadastro", "ato_criacao", "area_ha_ato",
                 "area_ha_poligono", "qualidade_poligono", "plano_manejo",
                 "geometry"], "unidade_conservacao.csv")
salvar_csv(pts, ["foco_id_inpe", "data_hora_gmt", "bioma", "cod_ibge", "id_uc",
                 "municipio_inpe", "geometry"], "foco_calor.csv")

total = len(mun) + len(ucs) + len(pts)
log()
log(f"TOTAL DE FEIÇÕES: {len(mun)} municípios + {len(ucs)} UCs + "
    f"{len(pts)} focos = {total}")

(TRATADOS / "log_tratamento.txt").write_text("\n".join(_log_linhas) + "\n",
                                             encoding="utf-8")
print(f"\nLog gravado em {TRATADOS / 'log_tratamento.txt'}")