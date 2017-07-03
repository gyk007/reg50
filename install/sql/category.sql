-- Категории товаров
-- step 0002
-- class: ALKO::Catalog::Category


BEGIN;


CREATE TABLE category (
        id          SERIAL,
        name        VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
        description VARCHAR(4096),
        visible     BOOL NOT NULL DEFAULT FALSE,

        PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE category_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    category        TO @@DBUSER@@;

COMMENT ON TABLE  category             IS 'категории товаров';
COMMENT ON COLUMN category.id          IS 'id';
COMMENT ON COLUMN category.name        IS 'наименование';
COMMENT ON COLUMN category.description IS 'описание';
COMMENT ON COLUMN category.visible     IS 'если false, категория скрыта со всем потомками';


INSERT INTO category VALUES (0, 'root', 'Невидимый корень каталога', false);


COMMIT;
