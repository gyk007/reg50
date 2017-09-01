-- Сессии
-- step 018
-- class: ALKO::Session

BEGIN;


-- таблица HTTP-сессий
CREATE TABLE session (
    id          SERIAL,
    token       VARCHAR(128) UNIQUE,
    id_merchant INTEGER REFERENCES merchant(id),
    id_shop     INTEGER REFERENCES shop(id),
    ctime       TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    ltime       TIMESTAMP(6) WITH TIME ZONE NOT NULL,

    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE session TO @@DBUSER@@;

COMMENT ON TABLE  session             IS 'HTTP-сессия';
COMMENT ON COLUMN session.id          IS 'id';
COMMENT ON COLUMN session.token       IS 'токен';
COMMENT ON COLUMN session.id_merchant IS 'пользователь';
COMMENT ON COLUMN session.id_shop     IS 'торговая точка';
COMMENT ON COLUMN session.ctime       IS 'время создания сессии';
COMMENT ON COLUMN session.ltime       IS 'время последнего визита';


-- таблица HTTP-сессий для регистрации клиента
CREATE TABLE reg_session (
    id          SERIAL,
    token       VARCHAR(128) UNIQUE,
    id_merchant INTEGER REFERENCES merchant(id),
    ctime       TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    dtime       TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    count       INTEGER NOT NULL,

    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE reg_session TO @@DBUSER@@;

COMMENT ON TABLE  reg_session             IS 'HTTP-сессии для регистрации';
COMMENT ON COLUMN reg_session.id          IS 'id';
COMMENT ON COLUMN reg_session.token       IS 'токен';
COMMENT ON COLUMN reg_session.id_merchant IS 'представитель';
COMMENT ON COLUMN reg_session.ctime       IS 'время создания сессии';
COMMENT ON COLUMN reg_session.dtime       IS 'время конца срока дейсвия сессии';
COMMENT ON COLUMN reg_session.count       IS 'количесво посещений по текущей сессии';

COMMIT;