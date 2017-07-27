-- Пользователи
-- step 0012
-- class: ALKO::Client

BEGIN;


CREATE TABLE client (
        id      SERIAL,
        name    VARCHAR(128) NOT NULL,
        person  VARCHAR(128),
        address VARCHAR(4096),
        phone   VARCHAR(128),
        email   VARCHAR(128),

        PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE client_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    client        TO @@DBUSER@@;

COMMENT ON TABLE  client          IS 'список клиентов';
COMMENT ON COLUMN client.id       IS 'id';
COMMENT ON COLUMN client.name     IS 'имя магазина';
COMMENT ON COLUMN client.person   IS 'имя торгового представителя';
COMMENT ON COLUMN client.address  IS 'адрес';
COMMENT ON COLUMN client.phone    IS 'телефон';
COMMENT ON COLUMN client.email    IS 'адрес электронной почты';


COMMIT;