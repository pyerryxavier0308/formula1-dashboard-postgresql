BEGIN;

SET client_encoding = 'UTF8';
SET datestyle TO ISO, YMD;

DROP TABLE IF EXISTS stg_circuits;
DROP TABLE IF EXISTS stg_constructors;
DROP TABLE IF EXISTS stg_drivers;
DROP TABLE IF EXISTS stg_races;
DROP TABLE IF EXISTS stg_driver_standings;
DROP TABLE IF EXISTS stg_constructor_standings;
DROP TABLE IF EXISTS stg_results;
DROP TABLE IF EXISTS stg_qualifying;
DROP TABLE IF EXISTS stg_airports;
DROP TABLE IF EXISTS stg_countries;
DROP TABLE IF EXISTS stg_time_zones;
DROP TABLE IF EXISTS stg_feature_codes;
DROP TABLE IF EXISTS stg_iso_language_codes;
DROP TABLE IF EXISTS stg_cities;
DROP TABLE IF EXISTS tmp_driver_standings_resolved;
DROP TABLE IF EXISTS tmp_constructor_standings_resolved;

CREATE TEMP TABLE stg_circuits (
    circuit_id      TEXT,
    name            TEXT,
    lat             DOUBLE PRECISION,
    long            DOUBLE PRECISION,
    locality        TEXT,
    country         TEXT,
    wikipedia_url   TEXT
);

CREATE TEMP TABLE stg_constructors (
    constructor_id  TEXT,
    name            TEXT,
    nationality     TEXT,
    wikipedia_url   TEXT
);

CREATE TEMP TABLE stg_drivers (
    driver_id       TEXT,
    givenname       TEXT,
    familyname      TEXT,
    nationality     TEXT,
    dob             DATE
);

CREATE TEMP TABLE stg_races (
    race_id         TEXT,
    season          INTEGER,
    round           INTEGER,
    race_name       TEXT,
    date            DATE,
    time            TEXT,
    circuit_id      TEXT
);

CREATE TEMP TABLE stg_driver_standings (
    load_id         BIGSERIAL PRIMARY KEY,
    season          INTEGER,
    round           INTEGER,
    driver_id       TEXT,
    position        INTEGER,
    points          NUMERIC(10,2),
    wins            INTEGER
);

CREATE TEMP TABLE stg_constructor_standings (
    load_id         BIGSERIAL PRIMARY KEY,
    season          INTEGER,
    round           INTEGER,
    constructor_id  TEXT,
    position        NUMERIC,
    points          NUMERIC(10,2),
    wins            INTEGER
);

CREATE TEMP TABLE stg_results (
    race_id         TEXT,
    driver_id       TEXT,
    constructor_id  TEXT,
    grid            INTEGER,
    position        VARCHAR(5),
    position_order  INTEGER,
    points          NUMERIC(10,2),
    laps            INTEGER,
    status          TEXT
);

CREATE TEMP TABLE stg_qualifying (
    race_id         TEXT,
    driver_id       TEXT,
    constructor_id  TEXT,
    position        NUMERIC,
    q1              TEXT,
    q2              TEXT,
    q3              TEXT
);

CREATE TEMP TABLE stg_airports (
    id                  INTEGER,
    ident               TEXT,
    type                TEXT,
    name                TEXT,
    latitude_deg        DOUBLE PRECISION,
    longitude_deg       DOUBLE PRECISION,
    elevation_ft        INTEGER,
    continent           TEXT,
    iso_country         TEXT,
    iso_region          TEXT,
    municipality        TEXT,
    scheduled_service   TEXT,
    icao_code           TEXT,
    iata_code           TEXT,
    gps_code            TEXT,
    local_code          TEXT,
    home_link           TEXT,
    wikipedia_link      TEXT,
    keywords            TEXT
);

CREATE TEMP TABLE stg_countries (
    id              INTEGER,
    code            TEXT,
    name            TEXT,
    continent       TEXT,
    wikipedia_link  TEXT,
    keywords        TEXT
);

CREATE TEMP TABLE stg_time_zones (
    country_code    TEXT,
    time_zone_name  TEXT,
    gmt_offset      NUMERIC(10,2),
    dst_offset      NUMERIC(10,2),
    raw_offset      NUMERIC(10,2)
);

CREATE TEMP TABLE stg_feature_codes (
    full_code       TEXT,
    name            TEXT,
    description     TEXT
);

CREATE TEMP TABLE stg_iso_language_codes (
    iso_639_3       TEXT,
    iso_639_2       TEXT,
    iso_639_1       TEXT,
    language_name   TEXT
);

CREATE TEMP TABLE stg_cities (
    geoname_id          BIGINT,
    name                TEXT,
    ascii_name          TEXT,
    alternate_names     TEXT,
    latitude            DOUBLE PRECISION,
    longitude           DOUBLE PRECISION,
    feature_class       TEXT,
    feature_code        TEXT,
    country_code        TEXT,
    cc2                 TEXT,
    admin1_code         TEXT,
    admin2_code         TEXT,
    admin3_code         TEXT,
    admin4_code         TEXT,
    population          BIGINT,
    elevation           INTEGER,
    dem                 INTEGER,
    time_zone_name      TEXT,
    modification_date   DATE
);

-- Ajuste os caminhos abaixo para a pasta local onde os arquivos foram baixados.
-- Exemplo: C:/labbd_p3_dados/

COPY stg_circuits              FROM 'C:/labbd_p3_dados/circuits.csv'                 WITH (FORMAT csv, HEADER true, ENCODING 'LATIN1');
COPY stg_constructors          FROM 'C:/labbd_p3_dados/constructors.csv'             WITH (FORMAT csv, HEADER true);
COPY stg_drivers               FROM 'C:/labbd_p3_dados/drivers.csv'                  WITH (FORMAT csv, HEADER true);
COPY stg_races                 FROM 'C:/labbd_p3_dados/races.csv'                    WITH (FORMAT csv, HEADER true);
COPY stg_driver_standings      (season, round, driver_id, position, points, wins)      FROM 'C:/labbd_p3_dados/driver_standings.csv'      WITH (FORMAT csv, HEADER true);
COPY stg_constructor_standings (season, round, constructor_id, position, points, wins) FROM 'C:/labbd_p3_dados/constructor_standings.csv' WITH (FORMAT csv, HEADER true);
COPY stg_results               FROM 'C:/labbd_p3_dados/results.csv'                  WITH (FORMAT csv, HEADER true);
COPY stg_qualifying            FROM 'C:/labbd_p3_dados/qualifying.csv'               WITH (FORMAT csv, HEADER true);

COPY stg_airports              FROM 'C:/labbd_p3_dados/airports.csv'                 WITH (FORMAT csv, HEADER true);
COPY stg_countries             FROM 'C:/labbd_p3_dados/countries.csv'                WITH (FORMAT csv, HEADER true);
COPY stg_time_zones            FROM 'C:/labbd_p3_dados/timeZones.tsv'                WITH (FORMAT csv, HEADER true, DELIMITER E'\t');
COPY stg_feature_codes         FROM 'C:/labbd_p3_dados/featureCodes_en.tsv'          WITH (FORMAT csv, HEADER false, DELIMITER E'\t');
COPY stg_iso_language_codes    FROM 'C:/labbd_p3_dados/iso-languagecodes.tsv'        WITH (FORMAT csv, HEADER true, DELIMITER E'\t');
COPY stg_cities                FROM 'C:/labbd_p3_dados/cities15000.tsv'              WITH (FORMAT csv, HEADER false, DELIMITER E'\t');

INSERT INTO continents (code, name)
SELECT DISTINCT
    c.continent,
    CASE c.continent
        WHEN 'AF' THEN 'Africa'
        WHEN 'AN' THEN 'Antarctica'
        WHEN 'AS' THEN 'Asia'
        WHEN 'EU' THEN 'Europe'
        WHEN 'NA' THEN 'North America'
        WHEN 'OC' THEN 'Oceania'
        WHEN 'SA' THEN 'South America'
        ELSE c.continent
    END
FROM stg_countries c
WHERE c.continent IS NOT NULL
ON CONFLICT (code) DO NOTHING;

INSERT INTO countries (code, name, wikipedia_link, keywords, continent_id)
SELECT
    s.code,
    s.name,
    s.wikipedia_link,
    s.keywords,
    ct.id
FROM stg_countries s
JOIN continents ct
    ON ct.code = s.continent
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    wikipedia_link = EXCLUDED.wikipedia_link,
    keywords = EXCLUDED.keywords,
    continent_id = EXCLUDED.continent_id;

INSERT INTO time_zones (name, gmt_offset, dst_offset, raw_offset)
SELECT DISTINCT
    s.time_zone_name,
    s.gmt_offset,
    s.dst_offset,
    s.raw_offset
FROM stg_time_zones s
WHERE s.time_zone_name IS NOT NULL
ON CONFLICT (name) DO NOTHING;

INSERT INTO language_names (name)
SELECT DISTINCT TRIM(s.language_name)
FROM stg_iso_language_codes s
WHERE TRIM(s.language_name) <> ''
ON CONFLICT (name) DO NOTHING;

INSERT INTO iso_language_codes (iso_639_3, iso_639_2, iso_639_1, language_id)
SELECT
    NULLIF(TRIM(s.iso_639_3), ''),
    NULLIF(TRIM(s.iso_639_2), ''),
    NULLIF(TRIM(s.iso_639_1), ''),
    ln.id
FROM stg_iso_language_codes s
JOIN language_names ln
    ON ln.name = TRIM(s.language_name)
ON CONFLICT DO NOTHING;

INSERT INTO feature_codes (feature_class, feature_code, name, description)
SELECT DISTINCT
    split_part(s.full_code, '.', 1),
    split_part(s.full_code, '.', 2),
    s.name,
    s.description
FROM stg_feature_codes s
WHERE s.full_code IS NOT NULL
  AND position('.' IN s.full_code) > 0
ON CONFLICT (feature_class, feature_code) DO NOTHING;

INSERT INTO cities (
    id,
    name,
    ascii_name,
    alternate_names,
    latitude,
    longitude,
    feature_code_id,
    country_id,
    time_zone_id,
    cc2,
    admin1_code,
    admin2_code,
    admin3_code,
    admin4_code,
    population,
    elevation,
    dem,
    modification_date
)
SELECT
    s.geoname_id,
    s.name,
    s.ascii_name,
    s.alternate_names,
    s.latitude,
    s.longitude,
    fc.id,
    c.id,
    tz.id,
    s.cc2,
    s.admin1_code,
    s.admin2_code,
    s.admin3_code,
    s.admin4_code,
    s.population,
    s.elevation,
    s.dem,
    s.modification_date
FROM stg_cities s
LEFT JOIN feature_codes fc
    ON fc.feature_class = s.feature_class
   AND fc.feature_code = s.feature_code
LEFT JOIN countries c
    ON c.code = s.country_code
LEFT JOIN time_zones tz
    ON tz.name = s.time_zone_name
WHERE c.id IS NOT NULL
ON CONFLICT (id) DO NOTHING;

SELECT setval(
    pg_get_serial_sequence('cities', 'id'),
    COALESCE((SELECT MAX(id) FROM cities), 1)
);

INSERT INTO cities (
    name,
    ascii_name,
    latitude,
    longitude,
    country_id
)
SELECT DISTINCT
    trim(s.municipality) AS name,
    trim(s.municipality) AS ascii_name,
    s.latitude_deg AS latitude,
    s.longitude_deg AS longitude,
    c.id AS country_id
FROM stg_airports s
JOIN countries c
    ON c.code = s.iso_country
WHERE s.municipality IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM cities ci
      WHERE lower(trim(ci.name)) = lower(trim(s.municipality))
        AND ci.country_id = c.id
  );

INSERT INTO cities (
    name,
    ascii_name,
    latitude,
    longitude,
    country_id
)
SELECT DISTINCT
    trim(s.locality) AS name,
    trim(s.locality) AS ascii_name,
    s.lat AS latitude,
    s.long AS longitude,
    c.id AS country_id
FROM stg_circuits s
JOIN countries c
    ON lower(trim(c.name)) = lower(trim(s.country))
WHERE s.locality IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM cities ci
      WHERE lower(trim(ci.name)) = lower(trim(s.locality))
        AND ci.country_id = c.id
  );

INSERT INTO airport_types (type)
SELECT DISTINCT s.type
FROM stg_airports s
WHERE s.type IS NOT NULL
ON CONFLICT (type) DO NOTHING;

INSERT INTO airports (
    ident,
    airport_type_id,
    name,
    latitude_deg,
    longitude_deg,
    elevation_ft,
    city_id,
    scheduled_service,
    icao_code,
    iata_code,
    gps_code,
    local_code,
    home_link,
    wikipedia_link,
    keywords
)
SELECT
    s.ident,
    at.id,
    s.name,
    s.latitude_deg,
    s.longitude_deg,
    s.elevation_ft,
    ci.id,
    s.scheduled_service,
    s.icao_code,
    s.iata_code,
    s.gps_code,
    s.local_code,
    s.home_link,
    s.wikipedia_link,
    s.keywords
FROM stg_airports s
JOIN airport_types at
    ON at.type = s.type
LEFT JOIN countries co
    ON co.code = s.iso_country
LEFT JOIN cities ci
    ON lower(trim(ci.name)) = lower(trim(s.municipality))
    AND ci.country_id = co.id
ON CONFLICT (ident) DO NOTHING;

INSERT INTO seasons (year)
SELECT DISTINCT season
FROM stg_races
WHERE season IS NOT NULL
ON CONFLICT (year) DO NOTHING;

INSERT INTO status (status)
SELECT DISTINCT status
FROM stg_results
WHERE status IS NOT NULL
ON CONFLICT (status) DO NOTHING;

INSERT INTO constructors (
    constructor_ref,
    name,
    nationality,
    wikipedia_url
)
SELECT DISTINCT
    s.constructor_id,
    s.name,
    s.nationality,
    s.wikipedia_url
FROM stg_constructors s
ON CONFLICT (constructor_ref) DO NOTHING;

INSERT INTO drivers (
    driver_ref,
    given_name,
    family_name,
    nationality,
    date_of_birth
)
SELECT DISTINCT
    s.driver_id,
    s.givenname,
    s.familyname,
    s.nationality,
    s.dob
FROM stg_drivers s
ON CONFLICT (driver_ref) DO NOTHING;

INSERT INTO circuits (
    circuit_ref,
    name,
    lat,
    long,
    city_id,
    wikipedia_url
)
SELECT DISTINCT
    s.circuit_id,
    s.name,
    s.lat,
    s.long,
    ci.id,
    s.wikipedia_url
FROM stg_circuits s
LEFT JOIN cities ci
    ON lower(trim(ci.name)) = lower(trim(s.locality))
LEFT JOIN countries co
    ON lower(trim(co.name)) = lower(trim(s.country))
ON CONFLICT (circuit_ref) DO NOTHING;

INSERT INTO races (
    race_ref,
    season_id,
    round,
    race_name,
    race_date,
    race_time,
    circuit_id
)
SELECT
    r.race_id,
    s.id,
    r.round,
    r.race_name,
    r.date,
    NULLIF(r.time, '')::TIME,
    c.id
FROM stg_races r
JOIN seasons s
    ON s.year = r.season
JOIN circuits c
    ON c.circuit_ref = r.circuit_id
ON CONFLICT (race_ref) DO NOTHING;

INSERT INTO qualifying (
    race_id,
    driver_id,
    constructor_id,
    position,
    q1,
    q2,
    q3
)
SELECT
    r.id,
    d.id,
    c.id,
    q.position,
    q.q1,
    q.q2,
    q.q3
FROM stg_qualifying q
JOIN races r
    ON r.race_ref = q.race_id
JOIN drivers d
    ON d.driver_ref = q.driver_id
JOIN constructors c
    ON c.constructor_ref = q.constructor_id
ON CONFLICT (race_id, driver_id) DO NOTHING;

INSERT INTO results (
    race_id,
    driver_id,
    constructor_id,
    grid,
    position,
    position_order,
    points,
    laps,
    status_id
)
SELECT
    r.id,
    d.id,
    c.id,
    s.grid,
    s.position,
    s.position_order,
    s.points,
    s.laps,
    st.id
FROM stg_results s
JOIN races r
    ON r.race_ref = s.race_id
JOIN drivers d
    ON d.driver_ref = s.driver_id
JOIN constructors c
    ON c.constructor_ref = s.constructor_id
JOIN status st
    ON st.status = s.status
ON CONFLICT (race_id, driver_id) DO NOTHING;

CREATE TEMP TABLE tmp_driver_standings_resolved AS
SELECT
    s.load_id,
    se.id AS season_id,
    s.round,
    s.position,
    s.points,
    s.wins,
    d.id AS driver_id
FROM stg_driver_standings s
JOIN seasons se
    ON se.year = s.season
JOIN drivers d
    ON d.driver_ref = s.driver_id;

DO $$
DECLARE
    rec RECORD;
    v_standings_id INTEGER;
BEGIN
    FOR rec IN
        SELECT *
        FROM tmp_driver_standings_resolved
        ORDER BY load_id
    LOOP
        INSERT INTO standings (season_id, round, position, points, wins)
        VALUES (rec.season_id, rec.round, rec.position::INTEGER, rec.points, rec.wins)
        RETURNING id INTO v_standings_id;

        INSERT INTO driver_standings (standing_id, driver_id)
        VALUES (v_standings_id, rec.driver_id);
    END LOOP;
END $$;

CREATE TEMP TABLE tmp_constructor_standings_resolved AS
SELECT
    s.load_id,
    se.id AS season_id,
    s.round,
    s.position,
    s.points,
    s.wins,
    c.id AS constructor_id
FROM stg_constructor_standings s
JOIN seasons se
    ON se.year = s.season
JOIN constructors c
    ON c.constructor_ref = s.constructor_id;

DO $$
DECLARE
    rec RECORD;
    v_standings_id INTEGER;
BEGIN
    FOR rec IN
        SELECT *
        FROM tmp_constructor_standings_resolved
        ORDER BY load_id
    LOOP
        INSERT INTO standings (season_id, round, position, points, wins)
        VALUES (rec.season_id, rec.round, rec.position::INTEGER, rec.points, rec.wins)
        RETURNING id INTO v_standings_id;

        INSERT INTO constructor_standings (standing_id, constructor_id)
        VALUES (v_standings_id, rec.constructor_id);
    END LOOP;
END $$;

COMMIT;
