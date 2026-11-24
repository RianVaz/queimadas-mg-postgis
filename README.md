# Focos de calor e unidades de conservação – RGINT de Ipatinga (MG), 2024–2025

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
| `categoria_uc` | — (domínio) | 4 | Categorias de UC e grupo (proteção integral / uso sustentável) |

**Total:** 681 feições espaciais · **SRID:** 4674 (SIRGAS 2000)

A descrição completa de tabelas, colunas, domínios e limitações está em
[`DICIONARIO.md`](DICIONARIO.md). O diagrama entidade-relacionamento está em
[`docs/der.png`](docs/der.png).

## Fontes e licenças

| Dado | Fonte e versão | URL | Data de coleta | Licença |
|---|---|---|---|---|
| Municípios | IBGE – Malha Municipal 2025 (MG) | https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2025/UFs/MG/ | 21/11/2026 | Dados abertos do IBGE (citar a fonte) |
| Unidades de conservação | MMA – Cadastro Nacional de Unidades de Conservação (CNUC), versão 2025_08 | https://dados.mma.gov.br/dataset/unidadesdeconservacao | 21/11/2026 | Creative Commons Atribuição (CC-BY) |
| Focos de calor | INPE – Programa Queimadas (BDQueimadas), satélite de referência, arquivos anuais 2024 e 2025 | https://dataserver-coids.inpe.br/queimadas/queimadas/focos/csv/anual/Brasil_sat_ref/ | 21/11/2026 | Dados abertos do INPE (citar a fonte) |

Detalhes de cada arquivo (nomes, tamanhos, colunas originais e filtros) estão em
[`dados/brutos/FONTES.md`](dados/brutos/FONTES.md).

**Licença deste repositório** (ver [`LICENSE`](LICENSE)): código (`scripts/` e `sql/`) sob
licença MIT; dados tratados e documentação sob Creative Commons Atribuição 4.0 (CC BY 4.0),
com atribuição obrigatória às fontes originais acima.

## Requisitos

| Software | Versão usada no teste |
|---|---|
| PostgreSQL | 18.4 |
| PostGIS | 3.7.0 (GEOS 3.15.0, PROJ 9.8.1) |
| Sistema operacional | Windows x86_64 |
| Python (apenas para refazer o tratamento) | 3.12 |
| Bibliotecas Python | ver `requirements.txt` |

Os comandos `createdb` e `psql` acompanham a instalação do PostgreSQL. A extensão PostGIS
precisa estar instalada no servidor (no Windows, pelo *Stack Builder* do instalador do
PostgreSQL; no Linux, pelo pacote `postgis` da distribuição).

## Estrutura do repositório

```
├── README.md              # este arquivo
├── DICIONARIO.md          # dicionário de dados
├── LICENSE                # licenças do código (MIT) e dos dados (CC BY 4.0)
├── requirements.txt       # bibliotecas Python
├── sql/
│   ├── schema.sql         # extensão, tabelas, restrições e índices
│   ├── dados.sql          # carga dos dados (\copy dos CSVs)
│   └── consultas.sql      # consultas de verificação e de exemplo
├── dados/
│   ├── brutos/            # arquivos originais + FONTES.md
│   └── tratados/          # CSVs prontos para importação (geometria em EWKT)
├── scripts/
│   ├── contar_focos.py    # contagem de focos usada para definir o recorte
│   ├── contar_ucs.py      # contagem das UCs na região
│   └── tratamento.py      # limpeza, reprojeção e validação
└── docs/
    ├── der.mmd            # código-fonte do diagrama (Mermaid)
    └── der.png            # diagrama entidade-relacionamento
```

## Como importar

Os dados estão em CSV com a geometria em EWKT (`SRID=4674;...`) e são carregados com o
comando `\copy` do `psql`. Os caminhos dos CSVs em `sql/dados.sql` são relativos, por isso
**todos os comandos devem ser executados na pasta raiz do repositório** (a pasta que contém
este `README.md`).

### 1. Baixar o repositório

```bash
git clone https://github.com/RianVaz/queimadas-mg-postgis.git
cd queimadas-mg-postgis
```

(Ou baixe o ZIP pelo botão **Code → Download ZIP** do GitHub, descompacte e abra um
terminal dentro da pasta.)

### 2. Criar o banco, as tabelas e carregar os dados

Os comandos são os mesmos no Linux, no macOS e no Windows (PowerShell, Prompt de Comando ou
Git Bash):

```bash
createdb queimadas_mg
psql -d queimadas_mg -f sql/schema.sql
psql -d queimadas_mg -f sql/dados.sql
```

O `schema.sql` cria a extensão PostGIS, apaga as tabelas se já existirem e as recria. O
`dados.sql` para no primeiro erro e, ao final, mostra as contagens. O resultado esperado é:

| tabela | registros |
|---|---|
| municipio | 44 |
| categoria_uc | 4 |
| unidade_conservacao | 13 |
| foco_calor | 624 |

### 3. Conferir (opcional)

```bash
psql -d queimadas_mg -f sql/consultas.sql
```

A primeira parte confere contagens, validade das geometrias, SRID e relações espaciais
(os resultados esperados estão comentados no arquivo); a segunda traz consultas de exemplo.

### Dicas para problemas comuns

- **`createdb` ou `psql` não reconhecido (Windows):** use o caminho completo, por exemplo
  `& "C:\Program Files\PostgreSQL\18\bin\psql.exe"` no PowerShell, ou adicione a pasta
  `C:\Program Files\PostgreSQL\18\bin` à variável de ambiente `PATH`.
- **Pedido de senha ou erro de autenticação:** informe o usuário do PostgreSQL com `-U`,
  por exemplo `createdb -U postgres queimadas_mg` e `psql -U postgres -d queimadas_mg -f sql/schema.sql`
  (no Windows, o instalador cria o usuário `postgres` com a senha escolhida na instalação).
  No Linux, também é possível usar `sudo -u postgres createdb queimadas_mg`.
- **`could not open extension control file ... postgis.control`:** o PostGIS não está
  instalado no servidor; instale-o (ver Requisitos) e rode o `schema.sql` de novo.
- **`dados/tratados/...: No such file or directory`:** o `psql` não foi executado na raiz
  do repositório; entre na pasta `queimadas-mg-postgis` e repita.

## Como refazer o tratamento (opcional)

Não é necessário para importar a base: os CSVs prontos já estão em `dados/tratados/`. Os
comandos abaixo regeneram esses arquivos a partir dos dados brutos.

```bash
python -m venv .venv
source .venv/bin/activate          # Linux / macOS
# .venv\Scripts\Activate.ps1       # Windows (PowerShell)
# .venv\Scripts\activate.bat       # Windows (Prompt de Comando)
# source .venv/Scripts/activate    # Windows (Git Bash)
pip install -r requirements.txt
python scripts/tratamento.py
```

No Linux, use `python3` no lugar de `python` se necessário.

## Como citar

> MAURICIO, Rian Vaz; LEITE, Vitor de Souza; MIRANDA, Gustavo Dias; FERREIRA, Vitor Gomes.
> **Focos de calor e unidades de conservação – RGINT de Ipatinga (MG), 2024–2025**. Base de
> dados geográficos. João Monlevade: UFOP, 2026. Disponível em:
> https://github.com/RianVaz/queimadas-mg-postgis.

Ao usar a base, cite também as fontes originais: IBGE (Malha Municipal 2025),
MMA (CNUC 2025_08) e INPE (Programa Queimadas).

## Autores

- Rian Vaz Mauricio
- Vitor de Souza Leite
- Gustavo Dias Miranda
- Vitor Gomes Ferreira
