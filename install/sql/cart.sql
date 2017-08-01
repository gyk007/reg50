-- Корзина
-- step 015
-- class: ALKO::Cart

BEGIN;


-- таблица корзин
CREATE TABLE cart  (
    id_merchant  INTEGER REFERENCES merchant(id),
    n            INTEGER NOT NULL DEFAULT 1,
    name         VARCHAR(128),

    PRIMARY KEY (id_merchant, n)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE cart TO @@DBUSER@@;

COMMENT ON TABLE  cart             IS 'корзина';
COMMENT ON COLUMN cart.id_merchant IS 'представитель';
COMMENT ON COLUMN cart.n           IS 'номер корзины';
COMMENT ON COLUMN cart.name        IS 'имя корзины';


-- таблица продуктов в корзине
CREATE TABLE pickedup  (
    id_merchant  INTEGER,
    ncart        INTEGER,
    id_product   INTEGER REFERENCES product(id),
    quantity     FLOAT   NOT NULL,

    FOREIGN KEY (id_merchant, ncart) references cart (id_merchant, n),
    PRIMARY KEY (id_merchant, ncart, id_product)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE pickedup TO @@DBUSER@@;

COMMENT ON TABLE  pickedup             IS 'товары в корзине';
COMMENT ON COLUMN pickedup.id_merchant IS 'представитель';
COMMENT ON COLUMN pickedup.ncart       IS 'номер корзины';
COMMENT ON COLUMN pickedup.id_product  IS 'товар';
COMMENT ON COLUMN pickedup.quantity    IS 'количество товара';


COMMIT;