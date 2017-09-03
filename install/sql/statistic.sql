-- Статистика
-- step 020
-- class: ALKO::Statistic

BEGIN; 


-- таблица статистики сети
CREATE TABLE stat_net  (
    id_net INTEGER REFERENCES net(id),
    name   VARCHAR(128),
    qty    INTEGER,
    price  DECIMAL(10, 2) CHECK (price >= 0),    
    PRIMARY KEY (id_net)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE stat_net TO @@DBUSER@@;

COMMENT ON TABLE  stat_net        IS 'статистка сети';
COMMENT ON COLUMN stat_net.id_net IS 'сеть';
COMMENT ON COLUMN stat_net.name   IS 'имя сети, избыточно но для скорости';
COMMENT ON COLUMN stat_net.qty    IS 'количество заказов';
COMMENT ON COLUMN stat_net.price  IS 'общая стоимость';


-- таблица статистики торговой точки
CREATE TABLE stat_shop  (
    id_shop INTEGER REFERENCES shop(id),
    name    VARCHAR(128),
    qty     INTEGER,
    price   DECIMAL(10, 2) CHECK (price >= 0),    
    PRIMARY KEY (id_shop)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE stat_shop TO @@DBUSER@@;

COMMENT ON TABLE  stat_shop         IS 'статистка торговой точки';
COMMENT ON COLUMN stat_shop.id_shop IS 'торговая точка';
COMMENT ON COLUMN stat_shop.name    IS 'имя торговой точки, избыточно но для скорости';
COMMENT ON COLUMN stat_shop.qty     IS 'количество заказов';
COMMENT ON COLUMN stat_shop.price   IS 'общая стоимость';


-- таблица статистики товаров
CREATE TABLE stat_product  (
    id_product INTEGER REFERENCES product(id),
    name       VARCHAR(128),
    qty        INTEGER,
    price      DECIMAL(10, 2) CHECK (price >= 0),    
    PRIMARY KEY (id_product)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE stat_product TO @@DBUSER@@;

COMMENT ON TABLE  stat_product            IS 'статистка товаров';
COMMENT ON COLUMN stat_product.id_product IS 'товар';
COMMENT ON COLUMN stat_product.name       IS 'название товара, избыточно но для скорости';
COMMENT ON COLUMN stat_product.qty        IS 'количество товара в заказах';
COMMENT ON COLUMN stat_product.price      IS 'общая стоимость';


COMMIT;