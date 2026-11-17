BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP TRIGGER IF EXISTS tr_users_driver ON drivers;
DROP TRIGGER IF EXISTS tr_users_constructor ON constructors;

DROP FUNCTION IF EXISTS sincroniza_usuario_driver();
DROP FUNCTION IF EXISTS sincroniza_usuario_constructor();
DROP FUNCTION IF EXISTS autenticar_usuario(TEXT, TEXT);
DROP FUNCTION IF EXISTS registrar_logout(INTEGER);

DROP TABLE IF EXISTS users_log;
DROP TABLE IF EXISTS users;

/* ============================================================
   Tabela USERS
   Guarda os usuários da aplicação.

   A coluna password armazena HASH da senha, não texto puro.
   ============================================================ */
CREATE TABLE users (
    userid      SERIAL PRIMARY KEY,
    login       VARCHAR(255) NOT NULL UNIQUE,
    password    TEXT NOT NULL,
    tipo        VARCHAR(20) NOT NULL,
    id_original INTEGER,

    CONSTRAINT ck_users_tipo
        CHECK (tipo IN ('Admin', 'Escuderia', 'Piloto')),

    CONSTRAINT uq_users_tipo_original
        UNIQUE (tipo, id_original)
);

COMMENT ON TABLE users IS 'Usuários da aplicação do Projeto Final P4';
COMMENT ON COLUMN users.login IS 'Login do usuário';
COMMENT ON COLUMN users.password IS 'Senha protegida por hash usando pgcrypto';
COMMENT ON COLUMN users.tipo IS 'Tipo do usuário: Admin, Escuderia ou Piloto';
COMMENT ON COLUMN users.id_original IS 'ID do piloto ou escuderia na tabela original';

/* ============================================================
   Tabela USERS_LOG
   Registra LOGIN e LOGOUT.
   ============================================================ */
CREATE TABLE users_log (
    id_log    SERIAL PRIMARY KEY,
    userid    INTEGER NOT NULL,
    acao      VARCHAR(20) NOT NULL,
    data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_users_log_user
        FOREIGN KEY (userid) REFERENCES users(userid),

    CONSTRAINT ck_users_log_acao
        CHECK (acao IN ('LOGIN', 'LOGOUT'))
);

COMMENT ON TABLE users_log IS 'Auditoria de login e logout dos usuários da aplicação';

/* ============================================================
   Usuário administrador
   Login: admin
   Senha: admin
   ============================================================ */
INSERT INTO users (login, password, tipo, id_original)
VALUES ('admin', crypt('admin', gen_salt('bf')), 'Admin', NULL);

/* ============================================================
   Usuários das escuderias
   Login: <constructor_ref>_c
   Senha: <constructor_ref>
   ============================================================ */
INSERT INTO users (login, password, tipo, id_original)
SELECT
    constructor_ref || '_c' AS login,
    crypt(constructor_ref, gen_salt('bf')) AS password,
    'Escuderia' AS tipo,
    id AS id_original
FROM constructors;

/* ============================================================
   Usuários dos pilotos
   Login: <driver_ref>_d
   Senha: <driver_ref>
   ============================================================ */
INSERT INTO users (login, password, tipo, id_original)
SELECT
    driver_ref || '_d' AS login,
    crypt(driver_ref, gen_salt('bf')) AS password,
    'Piloto' AS tipo,
    id AS id_original
FROM drivers;

/* ============================================================
   Função de autenticação
   Recebe login e senha digitados.
   Se estiver correto, registra LOGIN em users_log.
   ============================================================ */
CREATE OR REPLACE FUNCTION autenticar_usuario(
    p_login TEXT,
    p_senha TEXT
)
RETURNS TABLE (
    userid INTEGER,
    login VARCHAR,
    tipo VARCHAR,
    id_original INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH usuario_autenticado AS (
        SELECT
            u.userid,
            u.login,
            u.tipo,
            u.id_original
        FROM users u
        WHERE u.login = p_login
          AND u.password = crypt(p_senha, u.password)
    ),
    log_inserido AS (
        INSERT INTO users_log (userid, acao)
        SELECT ua.userid, 'LOGIN'
        FROM usuario_autenticado ua
        RETURNING users_log.userid
    )
    SELECT
        ua.userid,
        ua.login,
        ua.tipo,
        ua.id_original
    FROM usuario_autenticado ua;
END;
$$;

/* ============================================================
   Função para registrar logout
   ============================================================ */
CREATE OR REPLACE FUNCTION registrar_logout(
    p_userid INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO users_log (userid, acao)
    VALUES (p_userid, 'LOGOUT');
END;
$$;

/* ============================================================
   Trigger para pilotos
   Sempre que um piloto for criado ou tiver driver_ref alterado,
   o usuário correspondente é criado ou atualizado.
   ============================================================ */
CREATE OR REPLACE FUNCTION sincroniza_usuario_driver()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_login TEXT;
BEGIN
    v_login := NEW.driver_ref || '_d';

    IF EXISTS (
        SELECT 1
        FROM users
        WHERE login = v_login
          AND NOT (tipo = 'Piloto' AND id_original = NEW.id)
    ) THEN
        RAISE EXCEPTION 'Já existe usuário com o login %', v_login;
    END IF;

    INSERT INTO users (login, password, tipo, id_original)
    VALUES (
        v_login,
        crypt(NEW.driver_ref, gen_salt('bf')),
        'Piloto',
        NEW.id
    )
    ON CONFLICT (tipo, id_original)
    DO UPDATE SET
        login = EXCLUDED.login,
        password = EXCLUDED.password;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tr_users_driver
AFTER INSERT OR UPDATE OF driver_ref
ON drivers
FOR EACH ROW
EXECUTE FUNCTION sincroniza_usuario_driver();

/* ============================================================
   Trigger para escuderias
   Sempre que uma escuderia for criada ou tiver constructor_ref
   alterado, o usuário correspondente é criado ou atualizado.
   ============================================================ */
CREATE OR REPLACE FUNCTION sincroniza_usuario_constructor()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_login TEXT;
BEGIN
    v_login := NEW.constructor_ref || '_c';

    IF EXISTS (
        SELECT 1
        FROM users
        WHERE login = v_login
          AND NOT (tipo = 'Escuderia' AND id_original = NEW.id)
    ) THEN
        RAISE EXCEPTION 'Já existe usuário com o login %', v_login;
    END IF;

    INSERT INTO users (login, password, tipo, id_original)
    VALUES (
        v_login,
        crypt(NEW.constructor_ref, gen_salt('bf')),
        'Escuderia',
        NEW.id
    )
    ON CONFLICT (tipo, id_original)
    DO UPDATE SET
        login = EXCLUDED.login,
        password = EXCLUDED.password;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tr_users_constructor
AFTER INSERT OR UPDATE OF constructor_ref
ON constructors
FOR EACH ROW
EXECUTE FUNCTION sincroniza_usuario_constructor();

COMMIT;
