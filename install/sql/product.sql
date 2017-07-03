-- Товары
-- step 0004
-- class: ALKO::Catalog::Product, ALKO::Catalog::Product::Link


BEGIN;


CREATE TABLE product (
        id          SERIAL,
        name        VARCHAR(1024) NOT NULL DEFAULT 'UNKNOWN',
        face        VARCHAR(1024),
        visible     BOOL NOT NULL DEFAULT FALSE,
        description VARCHAR(4096),


        PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE product_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    product        TO @@DBUSER@@;

COMMENT ON TABLE  product             IS 'товар';
COMMENT ON COLUMN product.id          IS 'id';
COMMENT ON COLUMN product.name        IS 'наименование';
COMMENT ON COLUMN product.face        IS 'наименование, выводимое в каталоге';
COMMENT ON COLUMN product.visible     IS 'если false, товар не показывается покупателю';
COMMENT ON COLUMN product.description IS 'описание';


CREATE TABLE prodlink (
	id_category INTEGER REFERENCES category(id) ON UPDATE CASCADE,
	id_product  INTEGER REFERENCES product(id)  ON UPDATE CASCADE,
        face        VARCHAR(1024),

        PRIMARY KEY (id_category, id_product)
);

GRANT SELECT, UPDATE, INSERT ON TABLE prodlink TO @@DBUSER@@;

COMMENT ON TABLE  prodlink             IS 'размещение товара по категориям; один товар во многих категориях';
COMMENT ON COLUMN prodlink.id_category IS 'категория каталога';
COMMENT ON COLUMN prodlink.id_product  IS 'товар';
COMMENT ON COLUMN prodlink.face        IS 'наименование товара, переопределяющее наименования для конкретной категории';

CREATE INDEX ON prodlink (id_product);

COMMIT;
