## Malha municipal
- Órgão: IBGE – Malha Municipal 2025
- URL: https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2025/UFs/MG/
- Arquivos: MG_Municipios_2025.zip, MG_RG_Imediatas_2025.zip, MG_RG_Intermediarias_2025.zip
- Data de coleta: 21/11/2026
- Licença: dados abertos do IBGE (citar a fonte)
- SRC da malha: EPSG:4674 (SIRGAS 2000, geográfico, graus) 
- Colunas da malha municipal: CD_MUN, NM_MUN, CD_RGI, NM_RGI, CD_RGINT, NM_RGINT,
  CD_UF, NM_UF, SIGLA_UF, CD_REGIAO, NM_REGIAO, SIGLA_RG, CD_CONCURB, NM_CONCURB, AREA_KM2

## Recorte (decisão final)
- Área: Região Geográfica Intermediária de Ipatinga (CD_RGINT = 3105), 44 municípios
- Período: 01/01/2024 a 31/12/2025
- Justificativa: a Região Imediata de João Monlevade (310026) teve só 102 focos
  em 2024–2025; a intermediária, que a inclui, teve 624 focos.

## Focos de calor
- Colunas originais: id_bdq, foco_id, lat, lon, data_pas, pais, estado, municipio, bioma
- Contagem RGI 310026: 2024 = 74 ; 2025 = 28
- Contagem RGINT 3105: 2024 = 454 ; 2025 = 170

## Unidades de conservação
- Órgão: Ministério do Meio Ambiente – Cadastro Nacional de Unidades de Conservação (CNUC)
- Conjunto: https://dados.mma.gov.br/dataset/unidadesdeconservacao
- Arquivo: shp_cnuc_2025_08.zip (Polígono CNUC 2025_08 – UCs ativas em agosto de 2025)
- Dicionário da fonte: dicionario_cnuc_shapefile.pdf
- Data de coleta: 21/11/2026
- Licença: Creative Commons Atribuição (CC-BY)
- Justificativa da versão: download direto (reprodutível) e coerente com o período 2024–2025
- Conteúdo do zip: cnuc_2025_08.shp (polígonos, usado) e cnuc_2025_08_pontos.shp
  (UCs sem polígono, não usado)