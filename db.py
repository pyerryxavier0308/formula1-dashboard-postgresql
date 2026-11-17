import pandas as pd
import psycopg2
from psycopg2.extras import RealDictCursor


def conectar(host, port, database, user, password):
    return psycopg2.connect(
        host=host,
        port=port,
        dbname=database,
        user=user,
        password=password,
    )


def consultar_df(conn, sql, params=None):
    return pd.read_sql_query(sql, conn, params=params)


def consultar_um(conn, sql, params=None):
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(sql, params or [])
        return cur.fetchone()


def executar_retorno(conn, sql, params=None):
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(sql, params or [])
        linhas = cur.fetchall()
    conn.commit()
    return linhas


def executar(conn, sql, params=None):
    with conn.cursor() as cur:
        cur.execute(sql, params or [])
    conn.commit()
