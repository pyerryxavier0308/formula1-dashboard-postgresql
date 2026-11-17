BEGIN;

/* ============================================================
   P4 - PARTE 3
   Relatórios e índices
   ============================================================ */

DROP FUNCTION IF EXISTS relatorio_admin_status();
DROP FUNCTION IF EXISTS relatorio_admin_aeroportos_por_cidade(TEXT);
DROP FUNCTION IF EXISTS relatorio_admin_escuderias_pilotos();
DROP FUNCTION IF EXISTS relatorio_admin_corridas_total();
DROP FUNCTION IF EXISTS relatorio_admin_corridas_por_circuito();
DROP FUNCTION IF EXISTS relatorio_admin_corridas_detalhe();

DROP FUNCTION IF EXISTS relatorio_escuderia_vitorias_pilotos(INTEGER);
DROP FUNCTION IF EXISTS relatorio_escuderia_status(INTEGER);

DROP FUNCTION IF EXISTS relatorio_piloto_pontos_ano_corrida(INTEGER);
DROP FUNCTION IF EXISTS relatorio_piloto_status(INTEGER);

/* ============================================================
   ÍNDICES
   Criados para auxiliar filtros, junções e ordenações usados
   nos dashboards e relatórios do Projeto Final.
   ============================================================ */

CREATE INDEX IF NOT EXISTS idx_results_status
ON results(status_id);

CREATE INDEX IF NOT EXISTS idx_results_constructor_driver_position
ON results(constructor_id, driver_id, position_order);

CREATE INDEX IF NOT EXISTS idx_results_driver_race
ON results(driver_id, race_id);

CREATE INDEX IF NOT EXISTS idx_results_constructor_status
ON results(constructor_id, status_id);

CREATE INDEX IF NOT EXISTS idx_results_driver_status
ON results(driver_id, status_id);

CREATE INDEX IF NOT EXISTS idx_races_season_circuit
ON races(season_id, circuit_id);

CREATE INDEX IF NOT EXISTS idx_cities_country_name
ON cities(country_id, name);

CREATE INDEX IF NOT EXISTS idx_cities_lat_long
ON cities(latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_airports_city_type
ON airports(city_id, airport_type_id);

CREATE INDEX IF NOT EXISTS idx_airports_lat_long
ON airports(latitude_deg, longitude_deg);


/* ============================================================
   Função auxiliar de distância aproximada entre coordenadas.
   Retorna a distância em quilômetros usando a fórmula
   de Haversine.
   ============================================================ */

DROP FUNCTION IF EXISTS distancia_km(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION);

CREATE OR REPLACE FUNCTION distancia_km(
    lat1 DOUBLE PRECISION,
    lon1 DOUBLE PRECISION,
    lat2 DOUBLE PRECISION,
    lon2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT
        6371.0 * 2.0 * asin(
            sqrt(
                power(sin(radians(($3 - $1) / 2.0)), 2) +
                cos(radians($1)) * cos(radians($3)) *
                power(sin(radians(($4 - $2) / 2.0)), 2)
            )
        );
$$;


/* ============================================================
   RELATÓRIO 1 - ADMIN
   Quantidade de resultados por status.
   ============================================================ */

CREATE OR REPLACE FUNCTION relatorio_admin_status()
RETURNS TABLE (
    status_resultado TEXT,
    quantidade BIGINT
)
LANGUAGE sql
AS $$
    SELECT
        st.status AS status_resultado,
        COUNT(*) AS quantidade
    FROM results res
    JOIN status st
        ON st.id = res.status_id
    GROUP BY
        st.status
    ORDER BY
        quantidade DESC,
        st.status;
$$;


/* ============================================================
   RELATÓRIO 2 - ADMIN
   Recebe o nome de uma cidade.
   Para cada cidade brasileira com esse nome, apresenta
   aeroportos brasileiros a até 100 km, dos tipos
   medium_airport ou large_airport.
   ============================================================ */

CREATE OR REPLACE FUNCTION relatorio_admin_aeroportos_por_cidade(
    p_nome_cidade TEXT
)
RETURNS TABLE (
    cidade_pesquisada VARCHAR,
    codigo_iata VARCHAR,
    aeroporto TEXT,
    cidade_aeroporto VARCHAR,
    distancia_km NUMERIC,
    tipo_aeroporto VARCHAR
)
LANGUAGE sql
AS $$
    SELECT
        cidade_base.name AS cidade_pesquisada,
        a.iata_code AS codigo_iata,
        a.name AS aeroporto,
        cidade_aero.name AS cidade_aeroporto,
        ROUND(
            distancia_km(
                cidade_base.latitude,
                cidade_base.longitude,
                a.latitude_deg,
                a.longitude_deg
            )::NUMERIC,
            2
        ) AS distancia_km,
        at.type AS tipo_aeroporto
    FROM cities cidade_base
    JOIN countries pais_base
        ON pais_base.id = cidade_base.country_id
    JOIN airports a
        ON a.latitude_deg IS NOT NULL
       AND a.longitude_deg IS NOT NULL
    JOIN cities cidade_aero
        ON cidade_aero.id = a.city_id
    JOIN countries pais_aero
        ON pais_aero.id = cidade_aero.country_id
    JOIN airport_types at
        ON at.id = a.airport_type_id
    WHERE pais_base.code = 'BR'
      AND pais_aero.code = 'BR'
      AND LOWER(cidade_base.name) = LOWER(p_nome_cidade)
      AND at.type IN ('medium_airport', 'large_airport')
      AND distancia_km(
            cidade_base.latitude,
            cidade_base.longitude,
            a.latitude_deg,
            a.longitude_deg
          ) <= 100
    ORDER BY
        cidade_base.name,
        distancia_km,
        a.name;
$$;


/* ============================================================
   RELATÓRIO 3 - ADMIN, NÍVEL 1
   Lista escuderias cadastradas com quantidade de pilotos.
   ============================================================ */

CREATE OR REPLACE FUNCTION relatorio_admin_escuderias_pilotos()
RETURNS TABLE (
    escuderia VARCHAR,
    quantidade_pilotos BIGINT
)
LANGUAGE sql
AS $$
    SELECT
        c.name AS escuderia,
        COUNT(DISTINCT res.driver_id) AS quantidade_pilotos
    FROM constructors c
    LEFT JOIN results res
        ON res.constructor_id = c.id
    GROUP BY
        c.name
    ORDER BY
        c.name;
$$;


/* ============================================================
   RELATÓRIO 3 - ADMIN, NÍVEL 2
   Quantidade total de corridas cadastradas.
   ============================================================ */

CREATE OR REPLACE FUNCTION relatorio_admin_corridas_total()
RETURNS TABLE (
    quantidade_corridas BIGINT
)
LANGUAGE sql
AS $$
    SELECT COUNT(*) AS quantidade_corridas
    FROM races;
$$;


/* ============================================================
   RELATÓRIO 3 - ADMIN, NÍVEL 3
   Corridas por circuito, com quantidade mínima, média
   e máxima de voltas registradas nos resultados.
   ============================================================ */

CREATE OR REPLACE FUNCTION relatorio_admin_corridas_por_circuito()
RETURNS TABLE (
    circuito TEXT,
    quantidade_corridas BIGINT,
    minimo_voltas INTEGER,
    media_voltas NUMERIC,
    maximo_voltas INTEGER
)
LANGUAGE sql
AS $$
    SELECT
        c.name AS circuito,
        COUNT(DISTINCT r.id) AS quantidade_corridas,
        MIN(res.laps) AS minimo_voltas,
        ROUND(AVG(res.laps)::NUMERIC, 2) AS media_voltas,
        MAX(res.laps) AS maximo_voltas
    FROM circuits c
    JOIN races r
        ON r.circuit_id = c.id
    LEFT JOIN results res
        ON res.race_id = r.id
    GROUP BY
        c.name
    ORDER BY
        c.name;
$$;


/* ============================================================
   RELATÓRIO 3 - ADMIN, DETALHE
   Para cada corrida por circuito:
   - voltas registradas;
   - quantidade de pilotos participantes.
   ============================================================ */

CREATE OR REPLACE FUNCTION relatorio_admin_corridas_detalhe()
RETURNS TABLE (
    circuito TEXT,
    temporada INTEGER,
    rodada INTEGER,
    corrida TEXT,
    voltas_registradas INTEGER,
    pilotos_participantes BIGINT
)
LANGUAGE sql
AS $$
    SELECT
        c.name AS circuito,
        s.year AS temporada,
        r.round AS rodada,
        r.race_name AS corrida,
        MAX(res.laps) AS voltas_registradas,
        COUNT(DISTINCT res.driver_id) AS pilotos_participantes
    FROM races r
    JOIN seasons s
        ON s.id = r.season_id
    JOIN circuits c
        ON c.id = r.circuit_id
    LEFT JOIN results res
        ON res.race_id = r.id
    GROUP BY
        c.name,
        s.year,
        r.round,
        r.race_name
    ORDER BY
        c.name,
        s.year,
        r.round;
$$;


/* ============================================================
   RELATÓRIO 4 - ESCUDERIA
   Lista pilotos da escuderia e quantidade de vitórias.
   ============================================================ */

CREATE OR REPLACE FUNCTION relatorio_escuderia_vitorias_pilotos(
    p_constructor_id INTEGER
)
RETURNS TABLE (
    piloto TEXT,
    quantidade_vitorias BIGINT
)
LANGUAGE sql
AS $$
    SELECT
        d.given_name || ' ' || d.family_name AS piloto,
        COUNT(*) FILTER (WHERE res.position_order = 1) AS quantidade_vitorias
    FROM results res
    JOIN drivers d
        ON d.id = res.driver_id
    WHERE res.constructor_id = p_constructor_id
    GROUP BY
        d.given_name,
        d.family_name
    ORDER BY
        quantidade_vitorias DESC,
        piloto;
$$;


/* ============================================================
   RELATÓRIO 5 - ESCUDERIA
   Quantidade de resultados por status no escopo da escuderia.
   ============================================================ */

CREATE OR REPLACE FUNCTION relatorio_escuderia_status(
    p_constructor_id INTEGER
)
RETURNS TABLE (
    status_resultado TEXT,
    quantidade BIGINT
)
LANGUAGE sql
AS $$
    SELECT
        st.status AS status_resultado,
        COUNT(*) AS quantidade
    FROM results res
    JOIN status st
        ON st.id = res.status_id
    WHERE res.constructor_id = p_constructor_id
    GROUP BY
        st.status
    ORDER BY
        quantidade DESC,
        st.status;
$$;


/* ============================================================
   RELATÓRIO 6 - PILOTO
   Pontos por ano, apresentando as corridas em que pontuou.
   Restrito ao piloto logado.
   ============================================================ */

CREATE OR REPLACE FUNCTION relatorio_piloto_pontos_ano_corrida(
    p_driver_id INTEGER
)
RETURNS TABLE (
    temporada INTEGER,
    corrida TEXT,
    data_corrida DATE,
    pontos NUMERIC
)
LANGUAGE sql
AS $$
    SELECT
        s.year AS temporada,
        r.race_name AS corrida,
        r.race_date AS data_corrida,
        res.points AS pontos
    FROM results res
    JOIN races r
        ON r.id = res.race_id
    JOIN seasons s
        ON s.id = r.season_id
    WHERE res.driver_id = p_driver_id
      AND res.points > 0
    ORDER BY
        s.year,
        r.race_date,
        r.race_name;
$$;


/* ============================================================
   RELATÓRIO 7 - PILOTO
   Quantidade de resultados por status no escopo do piloto.
   ============================================================ */

CREATE OR REPLACE FUNCTION relatorio_piloto_status(
    p_driver_id INTEGER
)
RETURNS TABLE (
    status_resultado TEXT,
    quantidade BIGINT
)
LANGUAGE sql
AS $$
    SELECT
        st.status AS status_resultado,
        COUNT(*) AS quantidade
    FROM results res
    JOIN status st
        ON st.id = res.status_id
    WHERE res.driver_id = p_driver_id
    GROUP BY
        st.status
    ORDER BY
        quantidade DESC,
        st.status;
$$;

COMMIT;
