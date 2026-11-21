# Fontes dos dados brutos
 
Registro de origem de cada arquivo desta pasta. Os arquivos estão exatamente como foram
baixados, sem nenhuma alteração.
 
## Recorte (decisão final)
 
- **Área:** Região Geográfica Intermediária de Ipatinga (`CD_RGINT = 3105`), 44 municípios.
- **Período:** 01/01/2024 a 31/12/2025.
- **Justificativa:** a Região Geográfica Imediata de João Monlevade (`CD_RGI = 310026`,
  6 municípios), primeira opção por ser a região do campus, teve apenas 102 focos em
  2024–2025 (74 em 2024 e 28 em 2025), insuficiente para o mínimo de 500 feições. A
  Região Intermediária de Ipatinga, que a inclui, teve 624 focos no mesmo período
  (454 em 2024 e 170 em 2025).
- Contagens obtidas com `scripts/contar_focos.py` e `scripts/contar_ucs.py`.
## Malha municipal
 
- **Órgão:** IBGE – Malha Municipal 2025.
- **URL:** https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2025/UFs/MG/
- **Arquivos:**
  - `MG_Municipios_2025.zip` (31 MB) – usado;
  - `MG_RG_Imediatas_2025.zip` (11 MB) e `MG_RG_Intermediarias_2025.zip` (4,6 MB) –
    usados apenas para escolher o recorte.
- **Data de coleta:** 21/11/2026.
- **Licença:** dados abertos do IBGE (citar a fonte).
- **SRC:** EPSG:4674 (SIRGAS 2000, geográfico, graus).
- **Registros:** 853 municípios de MG; 44 na RGINT 3105.
- **Colunas originais:** `CD_MUN`, `NM_MUN`, `CD_RGI`, `NM_RGI`, `CD_RGINT`, `NM_RGINT`,
  `CD_UF`, `NM_UF`, `SIGLA_UF`, `CD_REGIAO`, `NM_REGIAO`, `SIGLA_RG`, `CD_CONCURB`,
  `NM_CONCURB`, `AREA_KM2`.
## Unidades de conservação
 
- **Órgão:** Ministério do Meio Ambiente – Cadastro Nacional de Unidades de Conservação (CNUC).
- **Conjunto:** https://dados.mma.gov.br/dataset/unidadesdeconservacao
- **Arquivo:** `shp_cnuc_2025_08.zip` (44 MB) – "Polígono CNUC 2025_08", UCs com registro
  ativo em agosto de 2025.
- **URL direta:** https://dados.mma.gov.br/dataset/44b6dc8a-dc82-4a84-8d95-1b0da7c85dac/resource/6ba9a557-87e8-4882-acb7-b3e0f0ea192d/download/shp_cnuc_2025_08.zip
- **Dicionário da fonte:** `dicionario_cnuc_shapefile.pdf`.
- **Data de coleta:** 21/11/2026.
- **Licença:** Creative Commons Atribuição (CC-BY).
- **Justificativa da versão:** as versões de 2026 só estão disponíveis por link externo
  (SharePoint do MMA), sem download direto; a 2025_08 tem download direto (reprodutível)
  e é coerente com o período dos focos (2024–2025).
- **Conteúdo do zip:**
  - `cnuc_2025_08.shp` – polígonos (usado);
  - `cnuc_2025_08_pontos.shp` – UCs cadastradas apenas como ponto (não usado).
- **SRC:** EPSG:4674.
- **Registros no Brasil:** 3.122 polígonos (2.654 Polygon e 467 MultiPolygon); 1 geometria inválida.
- **Na região:** 15 UCs tocam a RGINT 3105; **13 mantidas** (≥ 50% da área na região).
  - Excluídas: APA Santo Antônio (`3170.31.3170`, 0,2% na região) e APA Piracicaba
    (`3170.31.3168`, 1,0% na região), ambas do município de Itabira.
  - UCs só com ponto na região (não incluídas): 5.
- **Problema de codificação:** campos de texto truncados em 254 bytes no meio de
  caracteres UTF-8. Lidos em latin1 e reconvertidos para UTF-8 descartando o byte
  incompleto (função `ler_shp_utf8`).
- **Colunas originais:** `gml_id`, `docleg_id`, `uc_id`, `cd_cnuc`, `wdpa_pid`, `nome_uc`,
  `cria_ano`, `cria_ato`, `outro_ato`, `pl_manejo`, `co_gestor`, `quali_pol`, `ppgr`,
  `ha_total`, `ha_ato`, `esfera`, `uf`, `municipio`, `org_gestor`, `grupo`, `categoria`,
  `cat_iucn`, `amazonia`, `caatinga`, `cerrado`, `matlantica`, `pampa`, `pantanal`,
  `marinho`, `situacao`, `limite`.
## Focos de calor
 
- **Órgão:** INPE – Programa Queimadas (BDQueimadas), focos do satélite de referência.
- **URL:** https://dataserver-coids.inpe.br/queimadas/queimadas/focos/csv/anual/Brasil_sat_ref/
- **Arquivos:** `focos_br_ref_2024.zip` (11 MB) e `focos_br_ref_2025.zip` (5,7 MB).
- **Data de coleta:** 21/11/2026.
- **Licença:** dados abertos do INPE (citar a fonte).
- **SRC:** coordenadas geográficas em EPSG:4326 (WGS 84).
- **Registros no Brasil:** 278.299 em 2024 e 136.393 em 2025.
- **Na região:**
  - RGI 310026 (João Monlevade): 2024 = 74; 2025 = 28;
  - RGINT 3105 (Ipatinga): 2024 = 454; 2025 = 170 – **total 624**.
- **Colunas originais:** `id_bdq`, `foco_id`, `lat`, `lon`, `data_pas`, `pais`, `estado`,
  `municipio`, `bioma`.
## Total previsto
 
44 municípios + 13 UCs + 624 focos = **681 feições**.
 