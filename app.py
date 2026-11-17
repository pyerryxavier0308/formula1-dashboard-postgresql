import io
from datetime import date

import pandas as pd
import streamlit as st

from db import conectar, consultar_df, executar, executar_retorno

st.set_page_config(page_title="P4 - Fórmula 1", layout="wide")


def estado_inicial():
    st.session_state.setdefault("conectado", False)
    st.session_state.setdefault("conn", None)
    st.session_state.setdefault("usuario", None)


def obter_conexao():
    return st.session_state.get("conn")


def preparar_tabela(df):
    """
    Ajusta a exibição das tabelas da aplicação.

    A função mantém os nomes originais das colunas nas consultas SQL,
    mas apresenta nomes mais claros para o usuário. Também evita que anos
    sejam mostrados com separador de milhar e troca valores nulos por
    uma mensagem mais amigável.
    """
    if df.empty:
        return df

    df_formatado = df.copy()

    colunas_ano = {
        "temporada",
        "primeiro_ano",
        "ultimo_ano",
        "primeira_temporada",
        "ultima_temporada",
    }

    for coluna in df_formatado.columns:
        if coluna in colunas_ano:
            df_formatado[coluna] = df_formatado[coluna].apply(
                lambda valor: "" if pd.isna(valor) else str(int(valor))
            )

    df_formatado = df_formatado.where(pd.notnull(df_formatado), "Não informado")

    nomes_colunas = {
        "temporada": "Temporada",
        "rodada": "Rodada",
        "corrida": "Corrida",
        "circuito": "Circuito",
        "data_corrida": "Data da corrida",
        "horario": "Horário",
        "voltas_registradas": "Voltas registradas",
        "pilotos_participantes": "Pilotos participantes",
        "piloto": "Piloto",
        "escuderia": "Escuderia",
        "total_pontos": "Total de pontos",
        "pontos": "Pontos",
        "pontos_obtidos": "Pontos obtidos",
        "quantidade_vitorias": "Vitórias",
        "quantidade_pilotos": "Pilotos",
        "quantidade_corridas": "Corridas",
        "primeiro_ano": "Primeiro ano",
        "ultimo_ano": "Último ano",
        "primeira_temporada": "Primeira temporada",
        "ultima_temporada": "Última temporada",
        "minimo_voltas": "Mínimo de voltas",
        "media_voltas": "Média de voltas",
        "maximo_voltas": "Máximo de voltas",
        "status_resultado": "Status do resultado",
        "quantidade": "Quantidade",
        "cidade_pesquisada": "Cidade pesquisada",
        "codigo_iata": "Código IATA",
        "aeroporto": "Aeroporto",
        "cidade_aeroporto": "Cidade do aeroporto",
        "distancia_km": "Distância (km)",
        "tipo_aeroporto": "Tipo do aeroporto",
        "nome_completo": "Nome completo",
        "data_nascimento": "Data de nascimento",
        "pais_ou_nacionalidade": "País ou nacionalidade",
        "driver_id": "ID do piloto",
        "login_gerado": "Login gerado",
        "mensagem": "Mensagem",
        "driver_ref": "Código do piloto",
        "given_name": "Nome",
        "family_name": "Sobrenome",
        "date_of_birth": "Data de nascimento",
        "country_id": "ID do país",
        "constructor_ref": "Código da escuderia",
        "name": "Nome",
        "wikipedia_url": "URL da Wikipedia",
        "linha": "Linha",
        "erro": "Erro",
        "login": "Login",
        "tipo": "Tipo",
        "id_original": "ID original",
        "userid": "ID do usuário",
        "id_log": "ID do log",
        "acao": "Ação",
        "data_hora": "Data/hora",
    }

    return df_formatado.rename(columns=nomes_colunas)


def mostrar_tabela(df, titulo=None):
    if titulo:
        st.subheader(titulo)
    if df.empty:
        st.info("Nenhum registro encontrado.")
    else:
        st.dataframe(preparar_tabela(df), use_container_width=True, hide_index=True)


def tela_conexao():
    st.sidebar.header("Conexão com PostgreSQL")
    host = st.sidebar.text_input("Host", value="localhost", key="conn_host")
    port = st.sidebar.number_input("Porta", value=5432, step=1, key="conn_porta")
    database = st.sidebar.text_input("Banco", value="labbd_p3", key="conn_banco")
    user = st.sidebar.text_input("Usuário", value="postgres", key="conn_usuario")
    password = st.sidebar.text_input("Senha", type="password", key="conn_senha")

    if st.sidebar.button("Conectar", key="btn_conectar_banco"):
        try:
            conn = conectar(host, int(port), database, user, password)
            st.session_state.conn = conn
            st.session_state.conectado = True
            st.sidebar.success("Conectado ao banco.")
        except Exception as erro:
            st.session_state.conectado = False
            st.sidebar.error(f"Erro ao conectar: {erro}")


def tela_login():
    st.title("Projeto Final P4 - Fórmula 1")
    st.subheader("Login")

    login = st.text_input("Login", key="login_usuario")
    senha = st.text_input("Senha", type="password", key="login_senha")

    if st.button("Entrar", key="btn_entrar_sistema"):
        conn = obter_conexao()
        sql = """
            SELECT userid, login, tipo, id_original
            FROM autenticar_usuario(%s, %s);
        """
        try:
            linhas = executar_retorno(conn, sql, [login, senha])
            if not linhas:
                st.error("Login ou senha inválidos.")
            else:
                st.session_state.usuario = dict(linhas[0])
                st.success("Login realizado com sucesso.")
                st.rerun()
        except Exception as erro:
            conn.rollback()
            st.error(f"Erro ao autenticar: {erro}")

    st.caption("Exemplos: admin/admin, mclaren_c/mclaren, hamilton_d/hamilton.")


def botao_logout():
    usuario = st.session_state.usuario
    conn = obter_conexao()
    if st.sidebar.button("Sair", key="btn_sair_sistema"):
        try:
            executar(conn, "SELECT registrar_logout(%s);", [usuario["userid"]])
        except Exception:
            conn.rollback()
        st.session_state.usuario = None
        st.rerun()


def cabecalho_usuario():
    usuario = st.session_state.usuario
    st.sidebar.markdown("---")
    st.sidebar.write(f"**Usuário:** {usuario['login']}")
    st.sidebar.write(f"**Tipo:** {usuario['tipo']}")
    botao_logout()


def tela_admin_dashboard(conn):
    st.header("Dashboard do Administrador")

    sql_totais = "SELECT * FROM dashboard_admin_totais();"
    totais = consultar_df(conn, sql_totais)
    if not totais.empty:
        c1, c2, c3 = st.columns(3)
        c1.metric("Pilotos", int(totais.loc[0, "total_pilotos"]))
        c2.metric("Escuderias", int(totais.loc[0, "total_escuderias"]))
        c3.metric("Temporadas", int(totais.loc[0, "total_temporadas"]))

    col1, col2 = st.columns(2)
    with col1:
        mostrar_tabela(
            consultar_df(conn, "SELECT * FROM dashboard_admin_corridas_ultima_temporada();"),
            "Corridas da temporada mais recente",
        )
        mostrar_tabela(
            consultar_df(conn, "SELECT * FROM dashboard_admin_escuderias_ultima_temporada();"),
            "Escuderias da temporada mais recente",
        )
    with col2:
        mostrar_tabela(
            consultar_df(conn, "SELECT * FROM dashboard_admin_pilotos_ultima_temporada();"),
            "Pilotos da temporada mais recente",
        )


def tela_admin_acoes(conn):
    st.header("Ações do Administrador")

    with st.expander("Cadastrar escuderia", expanded=False):
        constructor_ref = st.text_input("Código da escuderia (constructor_ref)", key="adm_constructor_ref")
        nome = st.text_input("Nome da escuderia", key="adm_constructor_nome")
        country_id = st.number_input("ID do país (country_id)", min_value=1, step=1, key="adm_constructor_country")
        wikipedia_url = st.text_input("URL da Wikipedia", key="adm_constructor_url")

        if st.button("Inserir escuderia", key="btn_inserir_escuderia"):
            sql = """
                INSERT INTO constructors (constructor_ref, name, country_id, wikipedia_url)
                VALUES (%s, %s, %s, %s);
            """
            try:
                executar(conn, sql, [constructor_ref, nome, int(country_id), wikipedia_url or None])
                st.success("Escuderia cadastrada. Usuário criado automaticamente pela trigger.")
            except Exception as erro:
                conn.rollback()
                st.error(f"Erro ao cadastrar escuderia: {erro}")

    with st.expander("Cadastrar piloto", expanded=False):
        driver_ref = st.text_input("Código do piloto (driver_ref)", key="adm_driver_ref")
        given_name = st.text_input("Nome", key="adm_given_name")
        family_name = st.text_input("Sobrenome", key="adm_family_name")
        data_nasc = st.date_input("Data de nascimento", value=date(2000, 1, 1), key="adm_driver_data")
        country_id = st.number_input("ID do país (country_id)", min_value=1, step=1, key="adm_driver_country")

        if st.button("Inserir piloto", key="btn_inserir_piloto_admin"):
            sql = """
                INSERT INTO drivers (driver_ref, given_name, family_name, date_of_birth, country_id)
                VALUES (%s, %s, %s, %s, %s);
            """
            try:
                executar(conn, sql, [driver_ref, given_name, family_name, data_nasc, int(country_id)])
                st.success("Piloto cadastrado. Usuário criado automaticamente pela trigger.")
            except Exception as erro:
                conn.rollback()
                st.error(f"Erro ao cadastrar piloto: {erro}")


def tela_admin_relatorios(conn):
    st.header("Relatórios do Administrador")

    opcao = st.selectbox(
        "Escolha o relatório",
        [
            "Relatório 1 - Resultados por status",
            "Relatório 2 - Aeroportos brasileiros próximos a uma cidade",
            "Relatório 3 - Escuderias, corridas e circuitos",
        ],
        key="select_relatorio_admin",
    )

    if opcao.startswith("Relatório 1"):
        mostrar_tabela(consultar_df(conn, "SELECT * FROM relatorio_admin_status();"))

    elif opcao.startswith("Relatório 2"):
        cidade = st.text_input("Nome da cidade brasileira", value="São Paulo", key="admin_rel2_cidade")
        if st.button("Gerar relatório", key="btn_admin_rel2_gerar"):
            sql = "SELECT * FROM relatorio_admin_aeroportos_por_cidade(%s);"
            mostrar_tabela(consultar_df(conn, sql, [cidade]))

    else:
        mostrar_tabela(consultar_df(conn, "SELECT * FROM relatorio_admin_escuderias_pilotos();"), "Escuderias e quantidade de pilotos")
        mostrar_tabela(consultar_df(conn, "SELECT * FROM relatorio_admin_corridas_total();"), "Total de corridas")
        mostrar_tabela(consultar_df(conn, "SELECT * FROM relatorio_admin_corridas_por_circuito();"), "Resumo por circuito")
        mostrar_tabela(consultar_df(conn, "SELECT * FROM relatorio_admin_corridas_detalhe();"), "Detalhe das corridas")


def tela_escuderia_dashboard(conn, constructor_id):
    st.header("Dashboard da Escuderia")
    mostrar_tabela(consultar_df(conn, "SELECT * FROM dashboard_escuderia(%s);", [constructor_id]))


def tela_escuderia_acoes(conn, constructor_id):
    st.header("Ações da Escuderia")

    with st.expander("Consultar piloto por sobrenome", expanded=True):
        sobrenome = st.text_input("Sobrenome do piloto", value="Senna", key="esc_sobrenome_piloto")
        if st.button("Consultar piloto", key="btn_consultar_piloto_sobrenome"):
            sql = "SELECT * FROM consultar_piloto_escuderia_por_sobrenome(%s, %s);"
            mostrar_tabela(consultar_df(conn, sql, [constructor_id, sobrenome]))

    with st.expander("Inserir novos pilotos por arquivo", expanded=False):
        st.write("O arquivo CSV deve ter as colunas: driver_ref, given_name, family_name, date_of_birth, country_id")
        arquivo = st.file_uploader("Arquivo CSV", type=["csv"], key="upload_pilotos_csv")
        if arquivo is not None:
            df = pd.read_csv(arquivo)
            mostrar_tabela(df, "Prévia do arquivo")

            if st.button("Inserir pilotos do arquivo", key="btn_inserir_pilotos_arquivo"):
                obrigatorias = {"driver_ref", "given_name", "family_name", "date_of_birth", "country_id"}
                if not obrigatorias.issubset(df.columns):
                    st.error("O arquivo não contém todas as colunas obrigatórias.")
                else:
                    sucessos = []
                    erros = []
                    sql = """
                        SELECT *
                        FROM inserir_piloto_escuderia(%s, %s, %s, %s, %s, %s);
                    """
                    for i, linha in df.iterrows():
                        try:
                            resultado = executar_retorno(
                                conn,
                                sql,
                                [
                                    constructor_id,
                                    str(linha["driver_ref"]),
                                    str(linha["given_name"]),
                                    str(linha["family_name"]),
                                    pd.to_datetime(linha["date_of_birth"]).date(),
                                    int(linha["country_id"]),
                                ],
                            )
                            sucessos.extend(resultado)
                        except Exception as erro:
                            conn.rollback()
                            erros.append({"linha": i + 1, "erro": str(erro)})
                    if sucessos:
                        st.success(f"{len(sucessos)} piloto(s) inserido(s).")
                        mostrar_tabela(pd.DataFrame(sucessos))
                    if erros:
                        st.warning("Algumas linhas não foram inseridas.")
                        mostrar_tabela(pd.DataFrame(erros))


def tela_escuderia_relatorios(conn, constructor_id):
    st.header("Relatórios da Escuderia")
    opcao = st.selectbox("Escolha o relatório", ["Relatório 4 - Vitórias por piloto", "Relatório 5 - Resultados por status"], key="select_relatorio_escuderia")
    if opcao.startswith("Relatório 4"):
        mostrar_tabela(consultar_df(conn, "SELECT * FROM relatorio_escuderia_vitorias_pilotos(%s);", [constructor_id]))
    else:
        mostrar_tabela(consultar_df(conn, "SELECT * FROM relatorio_escuderia_status(%s);", [constructor_id]))


def tela_piloto_dashboard(conn, driver_id):
    st.header("Dashboard do Piloto")
    mostrar_tabela(consultar_df(conn, "SELECT * FROM dashboard_piloto_periodo(%s);", [driver_id]), "Período de participação")
    mostrar_tabela(consultar_df(conn, "SELECT * FROM dashboard_piloto_ano_circuito(%s);", [driver_id]), "Desempenho por temporada e circuito")


def tela_piloto_relatorios(conn, driver_id):
    st.header("Relatórios do Piloto")
    opcao = st.selectbox("Escolha o relatório", ["Relatório 6 - Pontos por ano e corrida", "Relatório 7 - Resultados por status"], key="select_relatorio_piloto")
    if opcao.startswith("Relatório 6"):
        mostrar_tabela(consultar_df(conn, "SELECT * FROM relatorio_piloto_pontos_ano_corrida(%s);", [driver_id]))
    else:
        mostrar_tabela(consultar_df(conn, "SELECT * FROM relatorio_piloto_status(%s);", [driver_id]))


def aplicacao():
    estado_inicial()
    tela_conexao()

    if not st.session_state.conectado:
        st.info("Conecte ao PostgreSQL pela barra lateral para iniciar.")
        return

    if st.session_state.usuario is None:
        tela_login()
        return

    cabecalho_usuario()
    conn = obter_conexao()
    usuario = st.session_state.usuario
    tipo = usuario["tipo"]
    id_original = usuario["id_original"]

    st.title("Base de Dados da Fórmula 1")

    if tipo == "Admin":
        aba_dashboard, aba_acoes, aba_relatorios = st.tabs(["Dashboard", "Ações", "Relatórios"])
        with aba_dashboard:
            tela_admin_dashboard(conn)
        with aba_acoes:
            tela_admin_acoes(conn)
        with aba_relatorios:
            tela_admin_relatorios(conn)

    elif tipo == "Escuderia":
        aba_dashboard, aba_acoes, aba_relatorios = st.tabs(["Dashboard", "Ações", "Relatórios"])
        with aba_dashboard:
            tela_escuderia_dashboard(conn, id_original)
        with aba_acoes:
            tela_escuderia_acoes(conn, id_original)
        with aba_relatorios:
            tela_escuderia_relatorios(conn, id_original)

    elif tipo == "Piloto":
        aba_dashboard, aba_relatorios = st.tabs(["Dashboard", "Relatórios"])
        with aba_dashboard:
            tela_piloto_dashboard(conn, id_original)
        with aba_relatorios:
            tela_piloto_relatorios(conn, id_original)


if __name__ == "__main__":
    aplicacao()
