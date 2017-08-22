-- Сессии
-- step 018
-- class: ALKO::Session

BEGIN;


-- таблица сессий
CREATE TABLE session (
    id          SERIAL,
    coockie     VARCHAR(128) UNIQUE,
    id_merchant INTEGER REFERENCES merchant(id),
    ctime       TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    ltime       TIMESTAMP(6) WITH TIME ZONE NOT NULL,

    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE session TO @@DBUSER@@;

COMMENT ON TABLE  session             IS 'сессия';
COMMENT ON COLUMN session.id          IS 'id';
COMMENT ON COLUMN session.coockie     IS 'куки';
COMMENT ON COLUMN session.id_merchant IS 'пользователь';
COMMENT ON COLUMN session.ctime       IS 'время создания сессии';
COMMENT ON COLUMN session.ltime       IS 'время последнего визита';


COMMIT;