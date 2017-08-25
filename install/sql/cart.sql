-- Корзина
-- step 015
-- class: ALKO::Cart

BEGIN;


-- таблица корзин
CREATE TABLE cart  (
    id_shop INTEGER REFERENCES shop(id),
    n       INTEGER NOT NULL DEFAULT 1,
    name    VARCHAR(128),

    PRIMARY KEY (id_shop, n)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE cart TO @@DBUSER@@;

COMMENT ON TABLE  cart         IS 'корзина';
COMMENT ON COLUMN cart.id_shop IS 'торговая точка';
COMMENT ON COLUMN cart.n       IS 'номер корзины';
COMMENT ON COLUMN cart.name    IS 'имя корзины';


-- таблица продуктов в корзине
CREATE TABLE pickedup  (
    id_shop      INTEGER,
    n            INTEGER NOT NULL DEFAULT 1,
    ncart        INTEGER,
    id_product   INTEGER REFERENCES product(id),
    quantity     FLOAT   NOT NULL,

    FOREIGN KEY (id_shop, ncart) references cart (id_shop, n),
    CONSTRAINT uniq_pickedup UNIQUE (id_shop, n, ncart, id_product),
    PRIMARY KEY (id_shop, n, ncart)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE pickedup TO @@DBUSER@@;

COMMENT ON TABLE  pickedup            IS 'товары в корзине';
COMMENT ON COLUMN pickedup.id_shop    IS 'торговая точка';
COMMENT ON COLUMN pickedup.n          IS 'номер товара в корзине';
COMMENT ON COLUMN pickedup.ncart      IS 'номер корзины';
COMMENT ON COLUMN pickedup.id_product IS 'товар';
COMMENT ON COLUMN pickedup.quantity   IS 'количество товара';


COMMIT;