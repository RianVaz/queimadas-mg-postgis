# Dicionário de dados – Focos de calor e unidades de conservação na RGINT de Ipatinga (MG)
 
## 1. Visão geral da base
 
| Item | Descrição |
|---|---|
| **Título** | Focos de calor e unidades de conservação – RGINT de Ipatinga (MG), 2024–2025 (`queimadas_mg`) |
| **Descrição e finalidade** | Base com os municípios da Região Geográfica Intermediária de Ipatinga (MG), as unidades de conservação que estão na região e os focos de calor detectados por satélite em 2024 e 2025. Finalidade: apoiar análises da ocorrência de fogo na vegetação dentro e no entorno de áreas protegidas, por município e ao longo do tempo. |
| **Fontes** | **Municípios:** IBGE, Malha Municipal 2025 (geoftp.ibge.gov.br). **Unidades de conservação:** MMA, Cadastro Nacional de Unidades de Conservação – CNUC, versão 2025_08 (dados.mma.gov.br). **Focos de calor:** INPE, Programa Queimadas, arquivos anuais do satélite de referência (dataserver-coids.inpe.br). URLs completas em `dados/brutos/FONTES.md`. |
| **Data de coleta** | 21/11/2026 (todas as fontes). |
| **Licença** | IBGE e INPE: dados abertos, com citação da fonte. CNUC/MMA: Creative Commons Atribuição (CC-BY). Licença do repositório: ver `LICENSE`. |
| **Cobertura espacial** | 44 municípios da Região Geográfica Intermediária de Ipatinga (código IBGE 3105), em Minas Gerais, incluindo a Região Imediata de João Monlevade. As UCs são mantidas com seus limites completos, mesmo quando ultrapassam levemente a região. |
| **Cobertura temporal** | Focos de 01/01/2024 a 31/12/2025. Malha municipal de 2025. UCs com registro ativo em agosto de 2025. |
| **SRID e justificativa** | **EPSG:4674 (SIRGAS 2000).** É o datum oficial do Brasil e o mesmo da malha do IBGE e do CNUC, o que evita reprojetar os polígonos. Apenas os focos, fornecidos em EPSG:4326 (WGS 84), foram reprojetados; a diferença entre os dois sistemas é inferior a 1 metro. Como as coordenadas estão em graus, medidas em metros nas consultas usam o tipo `geography` ou reprojetam para EPSG:31983 (SIRGAS 2000 / UTM 23S). |
| **Escala e precisão** | Malha municipal do IBGE em escala de referência 1:250.000. Focos de calor do satélite de referência com imprecisão de localização da ordem de 1 km (tamanho do pixel do sensor). Polígonos das UCs com qualidade variável, indicada na coluna `qualidade_poligono`; 4 das 13 UCs têm polígono que é uma estimativa dos limites. |
| **Tratamentos aplicados** | Executados por `scripts/tratamento.py`; contagens completas em `dados/tratados/log_tratamento.txt`. 1. Seleção dos municípios com `CD_RGINT = '3105'` (44 de 853). 2. Leitura do CNUC em latin1 com reconversão para UTF-8, por causa de textos truncados no meio de caracteres. 3. Correção de 1 geometria inválida do CNUC com `make_valid` (nenhuma inválida nos municípios). 4. Seleção das 15 UCs que interceptam a região e manutenção das 13 com ≥ 50% da área dentro dela (área calculada em EPSG:31983). 5. Conversão de todos os polígonos para MultiPolygon. 6. Junção dos focos de 2024 e 2025 (414.692 no Brasil) e seleção dos 624 que estão dentro da região; nenhum foco removido por falta de coordenada, data fora do período ou identificador repetido. 7. Reprojeção dos focos de EPSG:4326 para EPSG:4674. 8. Padronização dos nomes de colunas (snake_case, sem acentos), do texto (UTF-8, sem espaços extras) e dos códigos de domínio (ex.: `ESTADUAL`, `SEM_INFORMACAO`). 9. Conversão de `cria_ano` (DD-MM-AAAA) para data. 10. Atribuição de `cod_ibge` (município) e `id_uc` (UC) a cada foco por relação espacial; 27 focos ficaram dentro de UCs. Regra prevista para um foco em UCs sobrepostas: atribuir a UC de menor área (não houve nenhum caso). |
 
## 2. Descrição das tabelas
 
### Tabela `municipio`
 
Limites dos municípios da RGINT de Ipatinga. **Geometria:** MultiPolygon · **SRID:** 4674 · **Registros:** 44.
 
| Coluna | Tipo | Tam. / Domínio | Nulo? | PK / FK | Descrição | Exemplo |
|---|---|---|---|---|---|---|
| `cod_ibge` | integer | 7 dígitos | Não | PK | Código do município no IBGE (`CD_MUN`). | 3136207 |
| `nome` | varchar | 100 | Não | | Nome oficial do município (`NM_MUN`). | João Monlevade |
| `uf` | char | 2 · siglas de UF | Não | | Sigla da unidade da federação (`SIGLA_UF`). | MG |
| `cod_rgi` | char | 6 dígitos | Não | | Código da Região Geográfica Imediata (`CD_RGI`). | 310026 |
| `nome_rgi` | varchar | 100 | Não | | Nome da Região Geográfica Imediata (`NM_RGI`). | João Monlevade |
| `area_km2` | numeric | (12,3) · ≥ 0 | Não | | Área territorial em km², conforme a malha do IBGE (`AREA_KM2`). | 98.231 |
| `geom` | geometry | MultiPolygon, 4674 | Não | | Limite municipal. | (geometria) |
 
### Tabela `categoria_uc` (tabela de domínio)
 
Categorias de unidade de conservação presentes na base e o grupo a que pertencem, conforme o SNUC (Lei 9.985/2000). Sem geometria · **Registros:** 4.
 
| Coluna | Tipo | Tam. / Domínio | Nulo? | PK / FK | Descrição | Exemplo |
|---|---|---|---|---|---|---|
| `cod_categoria` | smallint | ver seção 4 | Não | PK | Código da categoria (interno desta base). | 1 |
| `descricao` | varchar | 60 · único | Não | | Nome da categoria, como no CNUC. | Parque |
| `grupo` | varchar | ver seção 4 | Não | | Grupo do SNUC a que a categoria pertence. | PROTECAO_INTEGRAL |
 
### Tabela `unidade_conservacao`
 
Unidades de conservação do CNUC com pelo menos 50% da área dentro da região. **Geometria:** MultiPolygon · **SRID:** 4674 · **Registros:** 13.
 
| Coluna | Tipo | Tam. / Domínio | Nulo? | PK / FK | Descrição | Exemplo |
|---|---|---|---|---|---|---|
| `id_uc` | integer | — | Não | PK | Identificador da UC no CNUC (`uc_id`). | 23245 |
| `cod_cnuc` | varchar | 12 · único | Não | | Código da UC no CNUC (`cd_cnuc`). | 0000.31.0394 |
| `nome` | varchar | 150 | Não | | Nome da UC (`nome_uc`). | PARQUE ESTADUAL DO RIO DOCE |
| `cod_categoria` | smallint | ver `categoria_uc` | Não | FK | Categoria da UC. Referencia `categoria_uc.cod_categoria`. | 1 |
| `esfera` | varchar | ver seção 4 | Não | | Esfera administrativa responsável (`esfera`). | ESTADUAL |
| `data_cadastro` | date | AAAA-MM-DD | Sim | | Data informada em `cria_ano` no CNUC. Ver limitações (seção 5). | 1944-07-15 |
| `ato_criacao` | varchar | 254 | Sim | | Ato legal de criação (`cria_ato`). | Decreto 1119 de 14-07-1944 |
| `area_ha_ato` | numeric | (12,2) · ≥ 0 | Sim | | Área em hectares segundo o ato legal (`ha_ato`). | 35976.00 |
| `area_ha_poligono` | numeric | (12,2) · ≥ 0 | Sim | | Área do polígono em hectares, segundo o CNUC (`ha_total`). | 36030.25 |
| `qualidade_poligono` | varchar | 254 | Sim | | Qualidade do polígono declarada no CNUC (`quali_pol`). | Polígono corresponde ao memorial descritivo |
| `plano_manejo` | varchar | ver seção 4 | Sim | | Indica se a UC tem plano de manejo (`pl_manejo`). | SIM |
| `geom` | geometry | MultiPolygon, 4674 | Não | | Limite da UC (completo, sem recorte pela região). | (geometria) |
 
### Tabela `foco_calor`
 
Focos de calor do satélite de referência do INPE dentro da região, em 2024 e 2025. **Geometria:** Point · **SRID:** 4674 · **Registros:** 624.
 
| Coluna | Tipo | Tam. / Domínio | Nulo? | PK / FK | Descrição | Exemplo |
|---|---|---|---|---|---|---|
| `id_foco` | integer | identidade, gerado pelo banco (não está no CSV) | Não | PK | Identificador interno do foco (`GENERATED ALWAYS AS IDENTITY`). | 1 |
| `foco_id_inpe` | varchar | 36 · único (UUID) | Não | | Identificador do foco no INPE (`foco_id`). | 217188ae-748b-3f73-a250-0966f9b23e7c |
| `data_hora_gmt` | timestamp | AAAA-MM-DD HH:MM:SS | Não | | Data e hora da passagem do satélite, em GMT (`data_pas`). | 2024-07-26 17:05:00 |
| `bioma` | varchar | ver seção 4 | Sim | | Bioma onde o foco foi detectado, segundo o INPE (`bioma`). | Mata Atlântica |
| `cod_ibge` | integer | 7 dígitos | Não | FK | Município onde o foco está, obtido por `ST_Within`. Referencia `municipio.cod_ibge`. | 3168705 |
| `id_uc` | integer | — | Sim | FK | UC onde o foco está, obtida por `ST_Within`; nulo quando o foco está fora de UC. Referencia `unidade_conservacao.id_uc`. | 2806 |
| `municipio_inpe` | varchar | 100 | Sim | | Nome do município informado pelo INPE, mantido para comparação com `cod_ibge`. | TIMÓTEO |
| `geom` | geometry | Point, 4674 | Não | | Localização do foco. | POINT(-42.60672 -19.58808) |
 
## 3. Relacionamentos
 
| Origem | Destino | Tipo | Descrição |
|---|---|---|---|
| `foco_calor.cod_ibge` | `municipio.cod_ibge` | FK 1:N | Cada foco está em um município. |
| `foco_calor.id_uc` | `unidade_conservacao.id_uc` | FK 1:N (opcional) | Um foco pode estar em uma UC; nulo quando está fora. |
| `unidade_conservacao.cod_categoria` | `categoria_uc.cod_categoria` | FK 1:N | Cada UC tem uma categoria. |
| `foco_calor.geom` | `municipio.geom` | Espacial | `ST_Within(foco_calor.geom, municipio.geom)`: usada para preencher `cod_ibge`. |
| `foco_calor.geom` | `unidade_conservacao.geom` | Espacial | `ST_Within(foco_calor.geom, unidade_conservacao.geom)`: usada para preencher `id_uc`. |
| `unidade_conservacao.geom` | `municipio.geom` | Espacial N:N | `ST_Intersects`: uma UC pode abranger vários municípios. |
| `foco_calor.geom` | `unidade_conservacao.geom` | Espacial | `ST_DWithin(..., 5000)` sobre `geography`: focos a até 5 km de uma UC (entorno). |
 
## 4. Domínios e códigos
 
| Coluna | Valor | Significado |
|---|---|---|
| `categoria_uc.cod_categoria` / `descricao` | 1 – Parque | Parque (estadual ou natural municipal) · PROTECAO_INTEGRAL |
| | 2 – Floresta | Floresta municipal · USO_SUSTENTAVEL |
| | 3 – Reserva Particular do Patrimônio Natural | RPPN · USO_SUSTENTAVEL |
| | 4 – Área de Proteção Ambiental | APA · USO_SUSTENTAVEL |
| `categoria_uc.grupo` | PROTECAO_INTEGRAL | Admite apenas uso indireto dos recursos naturais (ex.: Parque) |
| | USO_SUSTENTAVEL | Admite uso sustentável de parte dos recursos (ex.: APA, RPPN, Floresta) |
| `unidade_conservacao.esfera` | FEDERAL | UC gerida pela União (ex.: RPPNs reconhecidas pelo ICMBio) |
| | ESTADUAL | UC gerida pelo estado (ex.: IEF-MG) |
| | MUNICIPAL | UC gerida pelo município |
| `unidade_conservacao.plano_manejo` | SIM / NAO / SEM_INFORMACAO | Existência de plano de manejo, segundo o CNUC |
| `municipio.uf` | Siglas de UF | Nesta base, sempre MG |
| `foco_calor.bioma` | Mata Atlântica | Único valor presente na região (bioma informado pelo INPE) |
 
Os códigos de `cod_categoria` são internos a esta base e não equivalem a códigos do CNUC.
 
## 5. Qualidade e limitações
 
- **Foco de calor não é área queimada:** cada foco indica um pixel com fogo ativo no momento da passagem do satélite. Um mesmo incêndio pode gerar vários focos, e incêndios pequenos, rápidos ou encobertos por nuvens podem não ser detectados.
- **Apenas o satélite de referência:** a base usa só os focos do satélite de referência do INPE, que permite comparações ao longo do tempo, mas detecta menos focos que o conjunto de todos os satélites.
- **Precisão dos focos:** a localização tem incerteza da ordem de 1 km. Focos próximos de divisas municipais ou de limites de UC podem ser atribuídos à área vizinha.
- **UCs que ultrapassam a região:** 3 UCs têm entre 0,1% e 0,2% da área fora da região; foram mantidas com os limites completos. Duas APAs de Itabira (`3170.31.3170` e `3170.31.3168`), com 0,2% e 1,0% da área na região, foram excluídas.
- **UCs sem polígono:** 5 UCs da região estão no CNUC apenas como ponto (APA de Nova Era, APA de Santana do Paraíso, PNM Bosque Centenário, RPPN Fazenda Macedônia e RPPN Vila Ana Angélica) e não foram incluídas.
- **Polígonos estimados:** 4 das 13 UCs (as 3 RPPNs e a APA Tunico Farias) têm polígono que "é uma estimativa dos limites da UC". Na RPPN Monlevade, a área do polígono (28,38 ha) difere muito da área legal (518,7 ha).
- **Data em `cria_ano`:** apesar do nome, o campo do CNUC contém uma data, que nem sempre coincide com o ato de criação (ex.: APA Serra dos Cocais, com data de 2020 e lei de 2002). Por isso a coluna foi chamada de `data_cadastro`.
- **Textos truncados:** o shapefile do CNUC limita campos de texto a 254 bytes, e alguns textos foram cortados no meio de um caractere acentuado. O byte incompleto foi descartado; textos longos podem estar incompletos na origem. Há também caracteres trocados por "?" em alguns textos da fonte.
- **Erros de digitação da fonte:** a UC `5702.31.4752` se chama "ÁREA DE PRESERVAÇÃO AMBIENTAL RIO PIRACICABA", embora a categoria seja Área de Proteção Ambiental; o nome foi mantido como na fonte.
- **Temporalidade:** retrato das UCs em agosto de 2025 e dos focos de 2024–2025.
- **Município do INPE × município por posição:** os 624 focos caem no mesmo município indicado pelo INPE. As únicas 6 diferenças encontradas são de grafia (INPE: "PINGO D'ÁGUA"; IBGE: "Pingo-d'Água"), não de localização.
- **Bioma:** todos os focos da região estão na Mata Atlântica, então a coluna `bioma` tem um único valor nesta base.
- **Focos em UCs:** apenas 27 dos 624 focos (cerca de 4%) estão dentro de UCs, e o número depende da precisão de ~1 km dos focos e da qualidade dos polígonos.
 