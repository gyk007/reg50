-- Пользователи
-- step 0011
-- class: ALKO::Clients


BEGIN;

CREATE TABLE clients (
        id              SERIAL,
        name            VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
        representative  VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
        address         VARCHAR(4096),
        phone           VARCHAR(128),
        mail            VARCHAR(128),
        visible         BOOL NOT NULL DEFAULT FALSE,

        PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE clients_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    clients        TO @@DBUSER@@;

COMMENT ON TABLE  clients                IS 'список пользователей (магазинов)';
COMMENT ON COLUMN clients.id             IS 'id';
COMMENT ON COLUMN clients.name           IS 'имя магазина';
COMMENT ON COLUMN clients.representative IS 'имя представителя';
COMMENT ON COLUMN clients.address        IS 'адрес';
COMMENT ON COLUMN clients.phone          IS 'телефон';
COMMENT ON COLUMN clients.mail           IS 'описание';
COMMENT ON COLUMN clients.visible        IS 'если false, поьзователь скрыт';

COMMIT;