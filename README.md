# Focos de calor e unidades de conservação – RGINT de Ipatinga (MG), 2024–2025
 
> **Status:** em desenvolvimento. Coleta concluída; tratamento, carga no PostGIS e
> documentação final em andamento.
 
Base de dados geográficos que reúne os **focos de calor** detectados por satélite, as
**unidades de conservação (UCs)** e os **municípios** da Região Geográfica Intermediária
de Ipatinga (MG), que inclui a região de João Monlevade, nos anos de 2024 e 2025.
 
**Finalidade:** permitir análises da ocorrência de fogo na vegetação dentro e no entorno
de áreas protegidas, por município e ao longo do tempo.
 
Trabalho da disciplina **CSI803 – Banco de Dados Geográficos** (UFOP – Campus João
Monlevade), Prof. Bruno R. Monteiro.
 
## Conteúdo da base
 
| Tabela | Geometria | Registros | Descrição |
|---|---|---|---|
| `municipio` | MultiPolygon | 44 | Municípios da RGINT de Ipatinga |
| `unidade_conservacao` | MultiPolygon | 13 | UCs com ≥ 50% da área na região |
| `foco_calor` | Point | 624 | Focos do satélite de referência do INPE, 2024–2025 |
| `categoria_uc` | — (domínio) | — | Categorias de UC e grupo (proteção integral / uso sustentável) |
 
**Total:** 681 feições espaciais · **SRID:** 4674 (SIRGAS 2000)
 
A descrição completa de tabelas, colunas, domínios e limitações está em
[`DICIONARIO.md`](DICIONARIO.md).
 
## Fontes e licenças
 
| Dado | Fonte | Licença |
|---|---|---|
| Municípios | IBGE – Malha Municipal 2025 | Dados abertos do IBGE (citar a fonte) |
| Unidades de conservação | MMA – Cadastro Nacional de Unidades de Conservação (CNUC), versão 2025_08 | Creative Commons Atribuição (CC-BY) |
| Focos de calor | INPE – Programa Queimadas (BDQueimadas), satélite de referência | Dados abertos do INPE (citar a fonte) |
 
URLs, datas de coleta, versões e filtros estão em
[`dados/brutos/FONTES.md`](dados/brutos/FONTES.md).
 
## Requisitos
 
| Software | Versão |
|---|---|
| PostgreSQL | _a preencher_ |
| PostGIS | _a preencher_ |
| Python (apenas para refazer o tratamento) | 3.12 |
| Bibliotecas Python | ver `requirements.txt` |
 
## Estrutura do repositório
 
```
├── README.md              # este arquivo
├── DICIONARIO.md          # dicionário de dados
├── LICENSE
├── requirements.txt       # bibliotecas Python
├── sql/
│   ├── schema.sql         # extensão, tabelas, restrições e índices
│   ├── dados.sql          # carga dos dados
│   └── consultas.sql      # consultas de verificação e de exemplo
├── dados/
│   ├── brutos/            # arquivos originais + FONTES.md
│   └── tratados/          # CSVs prontos para importação
├── scripts/
│   ├── contar_focos.py    # contagem de focos usada para definir o recorte
│   ├── contar_ucs.py      # contagem das UCs na região
│   └── tratamento.py      # limpeza, reprojeção e validação
└── docs/
    └── der.png            # diagrama entidade-relacionamento
```
 
## Como importar
 
> _A preencher após a criação do `schema.sql` e do `dados.sql`._
 
```bash
# 1. Criar o banco
createdb queimadas_mg
 
# 2. Criar as tabelas
psql -d queimadas_mg -f sql/schema.sql
 
# 3. Carregar os dados (executar a partir da raiz do repositório)
psql -d queimadas_mg -f sql/dados.sql
 
# 4. Conferir
psql -d queimadas_mg -f sql/consultas.sql
```
 
## Como refazer o tratamento (opcional)
 
```bash
python3 -m venv .venv
source .venv/bin/activate          # Linux / macOS
# source .venv/Scripts/activate    # Windows (Git Bash)
pip install -r requirements.txt
python scripts/tratamento.py
```
 
## Como citar
 
> _Nomes dos autores_. **Focos de calor e unidades de conservação – RGINT de Ipatinga
> (MG), 2024–2025**. Base de dados geográficos. UFOP, 2026. Disponível em:
> _URL do repositório_.
 
Ao usar a base, cite também as fontes originais: IBGE (Malha Municipal 2025),
MMA (CNUC 2025_08) e INPE (Programa Queimadas).
 
## Autores
 
- _Nome 1_
- _Nome 2_
- _Nome 3_
- _Nome 4_
 