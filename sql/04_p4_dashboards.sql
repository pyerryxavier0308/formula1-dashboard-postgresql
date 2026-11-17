BEGIN;

/* ============================================================
   P4 - PARTE 2
   Funções de Dashboard
   ============================================================ */

DROP FUNCTION IF EXISTS dashboard_admin_totais();
DROP FUNCTION IF EXISTS dashboard_admin_corridas_ultima_temporada();
DROP FUNCTION IF EXISTS dashboard_admin_escuderias_ultima_temporada();
DROP FUNCTION IF EXISTS dashboard_admin_pilotos_ultima_temporada();

DROP FUNCTION IF EXISTS dashboard_escuderia(INTEGER);
DROP FUNCTION IF EXISTS dashboard_piloto_periodo(INTEGER);
DROP FUNCTION IF EXISTS dashboard_piloto_ano_circuito(INTEGER);

/* ============================================================
   DASHBOARD ADMIN - Totais gerais
   Quantidade total de pilotos, escuderias e temporadas.
   ============================================================ */
CREATE OR REPLACE FUNCTION dashboard_admin_totais()
RETURNS TABLE (
    total_pilotos BIGINT,
    total_escuderias BIGINT,
    total_temporadas BIGINT
)
LANGUAGE sql
AS $$
    SELECT
        (SELECT COUNT(*) FROM drivers) AS total_pilotos,
        (SELECT COUNT(*) FROM constructors) AS total_escuderias,
        (SELECT COUNT(*) FROM seasons) AS total_temporadas;
$$;


/* ============================================================
   DASHBOARD ADMIN - Corridas da temporada mais recente
   Lista corridas da última temporada da base.
   ============================================================ */
CREATE OR REPLACE FUNCTION dashboard_admin_corridas_ultima_temporada()
RETURNS TABLE (
    temporada INTEGER,
    rodada INTEGER,
    corrida TEXT,
    circuito TEXT,
    data_corrida DATE,
    horario TIME,
    voltas_registradas INTEGER
)
LANGUAGE sql
AS $$
    SELECT
        s.year AS temporada,
        r.round AS rodada,
        r.race_name AS corrida,
        c.name AS circuito,
        r.race_date AS data_corrida,
        r.race_time AS horario,
        MAX(res.laps) AS voltas_registradas
    FROM races r
    JOIN seasons s
        ON s.id = r.season_id
    JOIN circuits c
        ON c.id = r.circuit_id
    LEFT JOIN results res
        ON res.race_id = r.id
    WHERE s.year = (
        SELECT MAX(year)
        FROM seasons
    )
    GROUP BY
        s.year,
        r.round,
        r.race_name,
        c.name,
        r.race_date,
        r.race_time
    ORDER BY
        r.round;
$$;


/* ============================================================
   DASHBOARD ADMIN - Escuderias da temporada mais recente
   Lista escuderias que correram na última temporada,
   com total de pontos obtidos.
   ============================================================ */
CREATE OR REPLACE FUNCTION dashboard_admin_escuderias_ultima_temporada()
RETURNS TABLE (
    temporada INTEGER,
    escuderia VARCHAR,
    total_pontos NUMERIC
)
LANGUAGE sql
AS $$
    SELECT
        s.year AS temporada,
        c.name AS escuderia,
        SUM(res.points) AS total_pontos
    FROM results res
    JOIN races r
        ON r.id = res.race_id
    JOIN seasons s
        ON s.id = r.season_id
    JOIN constructors c
        ON c.id = res.constructor_id
    WHERE s.year = (
        SELECT MAX(year)
        FROM seasons
    )
    GROUP BY
        s.year,
        c.name
    ORDER BY
        total_pontos DESC,
        c.name;
$$;


/* ============================================================
   DASHBOARD ADMIN - Pilotos da temporada mais recente
   Lista pilotos que correram na última temporada,
   com total de pontos obtidos.
   ============================================================ */
CREATE OR REPLACE FUNCTION dashboard_admin_pilotos_ultima_temporada()
RETURNS TABLE (
    temporada INTEGER,
    piloto TEXT,
    total_pontos NUMERIC
)
LANGUAGE sql
AS $$
    SELECT
        s.year AS temporada,
        d.given_name || ' ' || d.family_name AS piloto,
        SUM(res.points) AS total_pontos
    FROM results res
    JOIN races r
        ON r.id = res.race_id
    JOIN seasons s
        ON s.id = r.season_id
    JOIN drivers d
        ON d.id = res.driver_id
    WHERE s.year = (
        SELECT MAX(year)
        FROM seasons
    )
    GROUP BY
        s.year,
        d.given_name,
        d.family_name
    ORDER BY
        total_pontos DESC,
        piloto;
$$;


/* ============================================================
   DASHBOARD ESCUDERIA
   Recebe o id da escuderia.
   Retorna:
   - quantidade de vitórias;
   - quantidade de pilotos diferentes;
   - primeiro e último ano com dados.
   ============================================================ */
CREATE OR REPLACE FUNCTION dashboard_escuderia(
    p_constructor_id INTEGER
)
RETURNS TABLE (
    escuderia VARCHAR,
    quantidade_vitorias BIGINT,
    quantidade_pilotos BIGINT,
    primeiro_ano INTEGER,
    ultimo_ano INTEGER
)
LANGUAGE sql
AS $$
    SELECT
        c.name AS escuderia,
        COUNT(*) FILTER (WHERE res.position_order = 1) AS quantidade_vitorias,
        COUNT(DISTINCT res.driver_id) AS quantidade_pilotos,
        MIN(s.year) AS primeiro_ano,
        MAX(s.year) AS ultimo_ano
    FROM constructors c
    LEFT JOIN results res
        ON res.constructor_id = c.id
    LEFT JOIN races r
        ON r.id = res.race_id
    LEFT JOIN seasons s
        ON s.id = r.season_id
    WHERE c.id = p_constructor_id
    GROUP BY
        c.name;
$$;


/* ============================================================
   DASHBOARD PILOTO - Período de participação
   Recebe o id do piloto.
   Retorna primeiro e último ano com resultados.
   ============================================================ */
CREATE OR REPLACE FUNCTION dashboard_piloto_periodo(
    p_driver_id INTEGER
)
RETURNS TABLE (
    piloto TEXT,
    primeira_temporada INTEGER,
    ultima_temporada INTEGER
)
LANGUAGE sql
AS $$
    SELECT
        d.given_name || ' ' || d.family_name AS piloto,
        MIN(s.year) AS primeira_temporada,
        MAX(s.year) AS ultima_temporada
    FROM drivers d
    LEFT JOIN results res
        ON res.driver_id = d.id
    LEFT JOIN races r
        ON r.id = res.race_id
    LEFT JOIN seasons s
        ON s.id = r.season_id
    WHERE d.id = p_driver_id
    GROUP BY
        d.given_name,
        d.family_name;
$$;


/* ============================================================
   DASHBOARD PILOTO - Ano e circuito
   Para cada ano e circuito em que o piloto competiu:
   - pontos obtidos;
   - vitórias;
   - total de corridas.
   ============================================================ */
CREATE OR REPLACE FUNCTION dashboard_piloto_ano_circuito(
    p_driver_id INTEGER
)
RETURNS TABLE (
    temporada INTEGER,
    circuito TEXT,
    pontos_obtidos NUMERIC,
    quantidade_vitorias BIGINT,
    quantidade_corridas BIGINT
)
LANGUAGE sql
AS $$
    SELECT
        s.year AS temporada,
        c.name AS circuito,
        SUM(res.points) AS pontos_obtidos,
        COUNT(*) FILTER (WHERE res.position_order = 1) AS quantidade_vitorias,
        COUNT(*) AS quantidade_corridas
    FROM results res
    JOIN races r
        ON r.id = res.race_id
    JOIN seasons s
        ON s.id = r.season_id
    JOIN circuits c
        ON c.id = r.circuit_id
    WHERE res.driver_id = p_driver_id
    GROUP BY
        s.year,
        c.name
    ORDER BY
        s.year,
        c.name;
$$;

COMMIT;
