"""Conta quantos focos do satélite de referência caem na região escolhida."""
import sys
import geopandas as gpd
import pandas as pd

ANO = sys.argv[1] if len(sys.argv) > 1 else "2025"
COD_RGI = "310026"  # Região Imediata de João Monlevade

# Municípios de MG
mun = gpd.read_file("zip://dados/brutos/MG_Municipios_2025.zip")
regiao = mun[mun["CD_RGI"] == COD_RGI]
cod_rgint = regiao["CD_RGINT"].iloc[0]
intermediaria = mun[mun["CD_RGINT"] == cod_rgint]

print(f"Região imediata {COD_RGI}: {len(regiao)} municípios")
print(f"Região intermediária {cod_rgint} ({regiao['NM_RGINT'].iloc[0]}): "
      f"{len(intermediaria)} municípios")

# Focos do Brasil inteiro no ano
focos = pd.read_csv(f"dados/brutos/focos_br_ref_{ANO}.zip")
print("\nColunas do arquivo de focos:", list(focos.columns))
print(f"Focos no Brasil em {ANO}: {len(focos)}")

col_lat = next(c for c in focos.columns if c.lower().startswith("lat"))
col_lon = next(c for c in focos.columns if c.lower().startswith("lon"))

pontos = gpd.GeoDataFrame(
    focos,
    geometry=gpd.points_from_xy(focos[col_lon], focos[col_lat]),
    crs="EPSG:4326",
).to_crs(mun.crs)

for nome, area in [("imediata", regiao), ("intermediária", intermediaria)]:
    dentro = gpd.sjoin(pontos, area[["CD_MUN", "NM_MUN", "geometry"]],
                       predicate="within")
    print(f"\nFocos na região {nome} em {ANO}: {len(dentro)}")
    print(dentro["NM_MUN"].value_counts().head(10).to_string())