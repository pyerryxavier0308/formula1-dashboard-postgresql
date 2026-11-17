BEGIN;

/* ============================================================
   P4 - PARTE 4
   Ações específicas da escuderia
   ============================================================ */

DROP FUNCTION IF EXISTS consultar_piloto_escuderia_por_sobrenome(INTEGER, TEXT);
DROP FUNCTION IF EXISTS inserir_piloto_escuderia(INTEGER, TEXT, TEXT, TEXT, DATE, INTEGER);

DROP TABLE IF EXISTS constructor_drivers_manual;

/* ============================================================
   Tabela auxiliar para associação manual entre escuderia e piloto.

   Decisão de projeto:
   A associação histórica entre piloto e escuderia aparece
   naturalmente na tabela RESULTS. Porém, quando uma escuderia
   cadastra um piloto novo por arquivo, ele ainda não possui
   resultado em corrida. Por isso, esta tabela registra a
   associação informada pela escuderia na aplicação.
   ============================================================ */

CREATE TABLE constructor_drivers_manual (
    id SERIAL PRIMARY KEY,
    constructor_id INTEGER NOT NULL,
    driver_id INTEGER NOT NULL,
    data_cadastro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_constructor_drivers_manual_constructor
        FOREIGN KEY (constructor_id) REFERENCES constructors(id),

    CONSTRAINT fk_constructor_drivers_manual_driver
        FOREIGN KEY (driver_id) REFERENCES drivers(id),

    CONSTRAINT uq_constructor_drivers_manual
        UNIQUE (constructor_id, driver_id)
);

COMMENT ON TABLE constructor_drivers_manual IS
'Associação manual entre escuderia e piloto criada no cadastro por arquivo do Projeto Final';


/* ============================================================
   Índices para as ações da escuderia.
   ============================================================ */

CREATE INDEX IF NOT EXISTS idx_drivers_family_name
ON drivers(LOWER(family_name));

CREATE INDEX IF NOT EXISTS idx_constructor_drivers_manual_constructor
ON constructor_drivers_manual(constructor_id);

CREATE INDEX IF NOT EXISTS idx_constructor_drivers_manual_driver
ON constructor_drivers_manual(driver_id);


/* ============================================================
   AÇÃO ESCUDERIA 1
   Consultar piloto por sobrenome.

   A função considera:
   - pilotos que já correram pela escuderia via RESULTS;
   - pilotos associados manualmente pela tabela auxiliar.
   ============================================================ */

CREATE OR REPLACE FUNCTION consultar_piloto_escuderia_por_sobrenome(
    p_constructor_id INTEGER,
    p_sobrenome TEXT
)
RETURNS TABLE (
    nome_completo TEXT,
    data_nascimento DATE,
    pais_ou_nacionalidade VARCHAR
)
LANGUAGE sql
AS $$
    SELECT DISTINCT
        d.given_name || ' ' || d.family_name AS nome_completo,
        d.date_of_birth AS data_nascimento,
        co.name AS pais_ou_nacionalidade
    FROM drivers d
    JOIN countries co
        ON co.id = d.country_id
    WHERE LOWER(d.family_name) = LOWER(p_sobrenome)
      AND (
            EXISTS (
                SELECT 1
                FROM results res
                WHERE res.driver_id = d.id
                  AND res.constructor_id = p_constructor_id
            )
            OR EXISTS (
                SELECT 1
                FROM constructor_drivers_manual cdm
                WHERE cdm.driver_id = d.id
                  AND cdm.constructor_id = p_constructor_id
            )
      )
    ORDER BY
        nome_completo;
$$;


/* ============================================================
   AÇÃO ESCUDERIA 2
   Inserir piloto novo.

   A aplicação deve ler o arquivo e chamar esta função
   para cada linha.

   Regras:
   - não pode existir outro piloto com mesmo nome e sobrenome;
   - insere em DRIVERS;
   - a trigger já criada em DRIVERS cria o usuário em USERS;
   - registra a associação manual com a escuderia logada.
   ============================================================ */

CREATE OR REPLACE FUNCTION inserir_piloto_escuderia(
    p_constructor_id INTEGER,
    p_driver_ref TEXT,
    p_given_name TEXT,
    p_family_name TEXT,
    p_date_of_birth DATE,
    p_country_id INTEGER
)
RETURNS TABLE (
    driver_id INTEGER,
    login_gerado TEXT,
    mensagem TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_driver_id INTEGER;
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM constructors
        WHERE id = p_constructor_id
    ) THEN
        RAISE EXCEPTION 'Escuderia com id % não encontrada.', p_constructor_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM countries
        WHERE id = p_country_id
    ) THEN
        RAISE EXCEPTION 'País com id % não encontrado.', p_country_id;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM drivers
        WHERE LOWER(given_name) = LOWER(p_given_name)
          AND LOWER(family_name) = LOWER(p_family_name)
    ) THEN
        RAISE EXCEPTION
            'Já existe piloto com o nome % %.',
            p_given_name,
            p_family_name;
    END IF;

    INSERT INTO drivers (
        driver_ref,
        given_name,
        family_name,
        date_of_birth,
        country_id
    )
    VALUES (
        p_driver_ref,
        p_given_name,
        p_family_name,
        p_date_of_birth,
        p_country_id
    )
    RETURNING id INTO v_driver_id;

    INSERT INTO constructor_drivers_manual (
        constructor_id,
        driver_id
    )
    VALUES (
        p_constructor_id,
        v_driver_id
    );

    RETURN QUERY
    SELECT
        v_driver_id,
        p_driver_ref || '_d',
        'Piloto inserido com sucesso. Usuário criado automaticamente pela trigger.'::TEXT;
END;
$$;

COMMIT;
