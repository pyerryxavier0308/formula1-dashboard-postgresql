# Sistema de Banco de Dados com Dashboard Web — Fórmula 1

Projeto acadêmico desenvolvido na disciplina **SCC-541 — Laboratório de Bases de Dados**, do **Instituto de Ciências Matemáticas e de Computação da Universidade de São Paulo (ICMC/USP)**, no **1º semestre de 2026**, sob orientação do **Prof. Caetano Traina Jr.**

A aplicação utiliza **Python, Streamlit e PostgreSQL** para consultar e gerenciar informações da Fórmula 1, com autenticação, dashboards, relatórios e operações específicas para diferentes perfis de usuário.

O projeto foi realizado no contexto de um trabalho acadêmico em grupo.

## 1. Tecnologias utilizadas

- **Python** — desenvolvimento da aplicação.
- **Streamlit** — interface web e dashboards.
- **PostgreSQL** — armazenamento e consultas aos dados.
- **SQL e PL/pgSQL** — criação da base, consultas, funções, triggers e relatórios.

## 2. Como os dados são utilizados

O aplicativo **consulta diretamente o banco PostgreSQL**. Ele não lê os arquivos CSV/TSV da pasta `dados/` a cada acesso aos dashboards.

Os arquivos CSV/TSV são utilizados **na preparação e carga inicial do banco**. Para recriar o projeto em outro computador, é necessário criar o banco, carregar os dados e executar os scripts SQL antes de iniciar a aplicação.

**Importante:** confira os caminhos dos arquivos no script de carga (`sql/carga.sql`) e ajuste-os para o local onde os dados estiverem armazenados. O caminho utilizado na máquina em que o projeto foi desenvolvido pode não funcionar em outro computador. Dependendo do comando de importação utilizado, o serviço PostgreSQL também precisa ter permissão para ler os arquivos.

## 3. Preparação do banco de dados

Crie um banco PostgreSQL, por exemplo `labbd_p3`, e execute os scripts abaixo na ordem indicada no projeto:

```text
sql/schema.sql
sql/carga.sql
sql/T1-Limpeza.sql
sql/03_p4_usuarios_login_triggers.sql
sql/04_p4_dashboards.sql
sql/05_p4_relatorios_indices.sql
sql/06_p4_acoes_escuderia.sql
```

Para conferências opcionais, utilize:

```text
sql/P4_teste.sql
```

Observação: o arquivo carga.sql utiliza o caminho C:/labbd_p3_dados/ para importar os dados. Para executar a carga inicial, é necessário disponibilizar os arquivos nesse diretório ou ajustar os caminhos no script.

## 4. Instalação da aplicação

Abra um terminal na pasta do projeto e crie um ambiente virtual:

```powershell
python -m venv .venv
```

No Windows (PowerShell), ative o ambiente:

```powershell
.\.venv\Scripts\Activate.ps1
```

No Linux/macOS:

```bash
source .venv/bin/activate
```

Instale as dependências:

```bash
python -m pip install -r requirements.txt
```

## 5. Execução

Com o ambiente virtual ativo, execute:

```bash
python -m streamlit run app.py
```

Abra o endereço local indicado no terminal, normalmente `http://localhost:8501`.

Na barra lateral da aplicação, informe os dados da sua instalação do PostgreSQL:

```text
Host: localhost
Porta: 5432
Banco: labbd_p3
Usuário: postgres
Senha: [senha configurada localmente]
```

A senha do banco **não deve ser publicada no repositório**.

## 6. Perfis e contas de demonstração

O sistema contempla três perfis: **administrador**, **escuderia** e **piloto**. Na base de demonstração, os seguintes acessos podem estar disponíveis após a carga e configuração dos scripts:

| Perfil | Login | Senha de demonstração |
| --- | --- | --- |
| Administrador | `admin` | `admin` |
| Escuderia | `mclaren_c` | `mclaren` |
| Piloto | `hamilton_d` | `hamilton` |

Essas credenciais são **apenas para testes acadêmicos**, não para um ambiente de produção.

## 7. Funcionalidades implementadas

- Autenticação de usuários por meio da função `autenticar_usuario`.
- Registro de login e logout em `users_log`.
- Dashboards e relatórios específicos para administrador, escuderia e piloto.
- Cadastro de escuderias e pilotos pelo administrador.
- Consulta de pilotos por sobrenome pela escuderia.
- Inserção de pilotos por arquivo CSV pela escuderia.

Os comandos SQL utilizados pela aplicação estão declarados explicitamente em `app.py`, conforme as orientações do trabalho acadêmico.

## 8. Arquivos de exemplo

A pasta `exemplos/` contém o arquivo `novos_pilotos.csv`, utilizado para demonstrar a importação de pilotos.

Exemplo de estrutura esperada:

```csv
driver_ref,given_name,family_name,date_of_birth,country_id
piloto_exemplo_1,Nome,Exemplo,2000-01-01,31
```

## 9. Contexto acadêmico e créditos

Este sistema foi desenvolvido como parte das atividades da disciplina **Laboratório de Bases de Dados — ICMC/USP**, no **1º semestre de 2026**, com o **Prof. Caetano Traina Jr.**

O desenvolvimento ocorreu em contexto acadêmico e em grupo. Os integrantes e suas contribuições podem ser apresentados conforme os registros da entrega original.
