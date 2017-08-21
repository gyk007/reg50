-- Заказ
-- step 017
-- class: ALKO::Order

BEGIN;


-- таблица статусов заказа
CREATE TABLE order_status (
    id          SERIAL,
    name        VARCHAR(128) NOT NULL,
    description TEXT,
    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE order_status TO @@DBUSER@@;

COMMENT ON TABLE  order_status             IS 'статус заказа';
COMMENT ON COLUMN order_status.id          IS 'id';
COMMENT ON COLUMN order_status.name        IS 'название статуса';
COMMENT ON COLUMN order_status.description IS 'описание статуса';

-- добавляем статусы
INSERT INTO order_status (id, name, description) VALUES (default, 'new',       '«Новый» - заказ принят системой обработки заказов. Уведомление формируется автоматически.');
INSERT INTO order_status (id, name, description) VALUES (default, 'accepted',  '«Принят в обработку» - заказ принят в обработку менеджером компании, который уточняет наличие ассортимента, цены и сроки поставки, согласовывает условия и сроки оплаты товара. При необходимости сотрудник связывается с клиентом для уточнения деталей. Уведомление формируется вручную.');
INSERT INTO order_status (id, name, description) VALUES (default, 'confirmed', '«Подтвержден» - заказ подтвержден клиентом. Цены, ассортимент, сроки и условия оплаты согласованы. Уведомление формируется вручную.');
INSERT INTO order_status (id, name, description) VALUES (default, 'suspended', '«В работе» - заказ принят в работу. Происходит комплектования заказа на складе. Уведомление формируется автоматически.');
INSERT INTO order_status (id, name, description) VALUES (default, 'pause',     '«Приостановлен» - обработка заказа остановлена до устранения причин препятствующих его выполнению. Уведомление формируется вручную.');
INSERT INTO order_status (id, name, description) VALUES (default, 'canceled',  '«Отменен» - заказ может быть отменен по желанию клиента в процессе согласований сроков и условий поставки. Уведомление формируется вручную.');
INSERT INTO order_status (id, name, description) VALUES (default, 'assembled', '«Собран» - заказ собран и готов к доставке. Уведомление формируется автоматически.');
INSERT INTO order_status (id, name, description) VALUES (default, 'deliver',   '«Доставляется» - заказ передан транспортной компании. Уведомление формируется автоматически.');
INSERT INTO order_status (id, name, description) VALUES (default, 'delivered', '«Доставлен» - заказ доставлен клиенту. Уведомление формируется автоматически.');
INSERT INTO order_status (id, name, description) VALUES (default, 'paid',      '«Оплачен» - заказ полностью оплачен клиентом. Уведомление формируется автоматически.');


-- таблица заказов
CREATE TABLE orders  (
    id               SERIAL,
    num              VARCHAR(128),
    id_status        INTEGER REFERENCES order_status(id),
    receivables      DECIMAL(10, 2),
    phone            VARCHAR(128),
    email            VARCHAR(128),
    address          VARCHAR(256),
    price            DECIMAL(10, 2),
    ctime            TIMESTAMP,
    name             VARCHAR(128),
    remark           TEXT,
    id_shop          INTEGER REFERENCES shop(id),
    id_merchant      INTEGER REFERENCES merchant(id),
    latch_number     VARCHAR(128),
    ttn_id           VARCHAR(128),
    ttn_number       VARCHAR(128),
    ttn_date         TIMESTAMP,
    deliver_date     TIMESTAMP,
    deliver_interval VARCHAR(128),
    deliver_name     VARCHAR(128),
    deliver_phone    VARCHAR(128),
    sales_name       VARCHAR(128),
    sales_phone      VARCHAR(128),
    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE orders TO @@DBUSER@@;

COMMENT ON TABLE  orders                  IS 'закза';
COMMENT ON COLUMN orders.id               IS 'id';
COMMENT ON COLUMN orders.num              IS 'номер заказа';
COMMENT ON COLUMN orders.id_status        IS 'статус';
COMMENT ON COLUMN orders.receivables      IS 'задолженность';
COMMENT ON COLUMN orders.phone            IS 'телефон';
COMMENT ON COLUMN orders.email            IS 'адрес электронной почты';
COMMENT ON COLUMN orders.address          IS 'адрес';
COMMENT ON COLUMN orders.price            IS 'стоимость заказа, избыточно, но для скорости';
COMMENT ON COLUMN orders.ctime            IS 'дата заказа';
COMMENT ON COLUMN orders.name             IS 'имя заказчика';
COMMENT ON COLUMN orders.remark           IS 'замечание';
COMMENT ON COLUMN orders.id_shop          IS 'торговая точка';
COMMENT ON COLUMN orders.id_merchant      IS 'представитель';
COMMENT ON COLUMN orders.latch_number     IS 'номер фиксации в ЕГАИС';
COMMENT ON COLUMN orders.ttn_id           IS 'идентификатор ТТН';
COMMENT ON COLUMN orders.ttn_number       IS 'номер ТТН';
COMMENT ON COLUMN orders.ttn_date         IS 'дата ТТН';
COMMENT ON COLUMN orders.deliver_date     IS 'дата доставки';
COMMENT ON COLUMN orders.deliver_interval IS 'период доставки';
COMMENT ON COLUMN orders.deliver_name     IS 'имя водителя';
COMMENT ON COLUMN orders.deliver_phone    IS 'телефон водителя';
COMMENT ON COLUMN orders.sales_name       IS 'имя торгового представителя Reg50';
COMMENT ON COLUMN orders.sales_phone      IS 'телефон торгового представителя Reg50';


-- таблица документов в заказе
CREATE TABLE order_document (
    id_order    INTEGER REFERENCES orders(id),
    name        VARCHAR(128),
    status      VARCHAR(128),
    file_name   VARCHAR(128),
    n           INTEGER,
    PRIMARY KEY (n, id_order)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE order_document TO @@DBUSER@@;

COMMENT ON TABLE  order_document           IS 'документ в заказе';
COMMENT ON COLUMN order_document.id_order  IS 'заказ';
COMMENT ON COLUMN order_document.name      IS 'имя';
COMMENT ON COLUMN order_document.status    IS 'статус документа';
COMMENT ON COLUMN order_document.file_name IS 'имя файла';
COMMENT ON COLUMN order_document.n         IS 'порядковый номер';


-- таблица товаров в заказе
CREATE TABLE order_product (
    id_order   INTEGER REFERENCES orders(id),
    id_product INTEGER REFERENCES product(id),
    price      DECIMAL(10, 2),
    qty        VARCHAR(128),
    PRIMARY KEY (id_order, id_product)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE order_product TO @@DBUSER@@;

COMMENT ON TABLE  order_product            IS 'товар в заказе';
COMMENT ON COLUMN order_product.id_order   IS 'заказ';
COMMENT ON COLUMN order_product.id_product IS 'товар';
COMMENT ON COLUMN order_product.price      IS 'цена товара во время заказа';
COMMENT ON COLUMN order_product.qty        IS 'количесво';


COMMIT;