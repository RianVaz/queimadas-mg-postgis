"""Conta as UCs do CNUC que tocam a RGINT de Ipatinga e os focos dentro delas."""
import geopandas as gpd
import pandas as pd

COD_RGINT = "3105"
CNUC_ZIP = "zip://dados/brutos/shp_cnuc_2025_08.zip"
pd.set_option("display.max_columns", None)
pd.set_option("display.width", 250)


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


# Limite da região (44 municípios dissolvidos em um polígono)
mun = gpd.read_file("zip://dados/brutos/MG_Municipios_2025.zip")
regiao = mun[mun["CD_RGINT"] == COD_RGINT]
limite = regiao.dissolve().geometry.iloc[0]

# UCs do Brasil (camada de polígonos)
ucs = ler_shp_utf8(f"{CNUC_ZIP}!cnuc_2025_08.shp")
print("Colunas:", list(ucs.columns))
print("SRC original:", ucs.crs)
print("Total de UCs no Brasil:", len(ucs))
print("Geometrias inválidas (Brasil):", (~ucs.is_valid).sum())
print("Tipos de geometria:", ucs.geom_type.value_counts().to_dict())

ucs = ucs.to_crs(regiao.crs)
ucs["geometry"] = ucs.make_valid()

na_regiao = ucs[ucs.intersects(limite)]
inteiras = na_regiao.within(limite).sum()
print(f"\nUCs que tocam a RGINT {COD_RGINT}: {len(na_regiao)}")
print(f"  totalmente dentro: {inteiras}")
print(f"  ultrapassam o limite: {len(na_regiao) - inteiras}")
print("\nPrimeiras linhas:")
print(na_regiao.drop(columns="geometry").head(10))

# Quanto de cada UC fica dentro da região
regiao_utm = gpd.GeoSeries([limite], crs=regiao.crs).to_crs(31983).iloc[0]
na_regiao_utm = na_regiao.to_crs(31983)
na_regiao = na_regiao.assign(
    pct_dentro=(na_regiao_utm.intersection(regiao_utm).area
                / na_regiao_utm.area * 100).round(1).values
)
print("\nTodas as UCs que tocam a região:")
print(na_regiao[["cd_cnuc", "nome_uc", "categoria", "esfera", "ha_total",
                 "quali_pol", "pct_dentro"]]
      .sort_values("pct_dentro").to_string())

# Focos 2024 + 2025 dentro das UCs
focos = pd.concat(
    [
        pd.read_csv("dados/brutos/focos_br_ref_2024.zip"),
        pd.read_csv("dados/brutos/focos_br_ref_2025.zip"),
    ],
    ignore_index=True,  # evita índices repetidos entre os dois anos
)
pontos = gpd.GeoDataFrame(
    focos, geometry=gpd.points_from_xy(focos["lon"], focos["lat"]), crs="EPSG:4326"
).to_crs(regiao.crs)
pontos = pontos[pontos.within(limite)]
em_uc = gpd.sjoin(pontos, na_regiao[["geometry"]], predicate="within")
print(f"\nFocos 2024–2025 na região: {len(pontos)}")
print(f"Focos dentro de alguma UC: {em_uc.index.nunique()}")

print(f"\nTOTAL DE FEIÇÕES: {len(regiao)} municípios + {len(na_regiao)} UCs "
      f"+ {len(pontos)} focos = {len(regiao) + len(na_regiao) + len(pontos)}")

# UCs cadastradas apenas como ponto (sem polígono)
ucs_pt = ler_shp_utf8(f"{CNUC_ZIP}!cnuc_2025_08_pontos.shp")
ucs_pt = ucs_pt.to_crs(regiao.crs)
pt_regiao = ucs_pt[ucs_pt.within(limite)]
print(f"\nUCs só com ponto (sem polígono) na região: {len(pt_regiao)}")
if len(pt_regiao):
    print(pt_regiao.drop(columns="geometry").head(10))