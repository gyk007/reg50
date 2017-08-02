-- Торговый представитель
-- step 014
-- class: ALKO::Merchant

BEGIN;


-- таблица представителей
CREATE TABLE merchant (
    id       SERIAL,
    password VARCHAR(128) NOT NULL,
    email    VARCHAR(128) NOT NULL UNIQUE,
    name     VARCHAR(128),
    phone    VARCHAR(128),
    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE merchant_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    merchant        TO @@DBUSER@@;

COMMENT ON TABLE  merchant           IS 'торговый представитель';
COMMENT ON COLUMN merchant.id        IS 'id';
COMMENT ON COLUMN merchant.password  IS 'пароль';
COMMENT ON COLUMN merchant.email     IS 'адрес электронной почты. Логин';
COMMENT ON COLUMN merchant.name      IS 'имя';
COMMENT ON COLUMN merchant.phone     IS 'телефон';


-- таблица сетей
CREATE TABLE net (
    id          SERIAL,
    id_official INTEGER REFERENCES official(id) UNIQUE,
    id_merchant INTEGER NOT NULL REFERENCES merchant(id) UNIQUE,
    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE net_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    net        TO @@DBUSER@@;

COMMENT ON TABLE  net             IS 'торговая сеть';
COMMENT ON COLUMN net.id          IS 'id';
COMMENT ON COLUMN net.id_official IS 'реквизиты';
COMMENT ON COLUMN net.id_merchant IS 'представитель';


-- таблица торговых точек
CREATE TABLE shop (
    id                    SERIAL,
    id_merchant           INTEGER NOT NULL REFERENCES merchant(id) UNIQUE,
    id_net                INTEGER REFERENCES net(id),
    id_official           INTEGER REFERENCES official(id) UNIQUE,
    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE shop_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    shop        TO @@DBUSER@@;

COMMENT ON TABLE  shop             IS 'торговая точка';
COMMENT ON TABLE  shop.id          IS 'id';
COMMENT ON COLUMN shop.id_merchant IS 'представитель';
COMMENT ON COLUMN shop.id_net      IS 'сеть';
COMMENT ON COLUMN shop.id_official IS 'реквизиты';


-- таблица файлов
CREATE TABLE file (
    id   SERIAL,
    path VARCHAR(128) NOT NULL,
    name VARCHAR(128) NOT NULL,
    ext  VARCHAR(128),
    size BIGINT NOT NULL,
    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE file_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    file        TO @@DBUSER@@;

COMMENT ON TABLE  file      IS 'файл';
COMMENT ON TABLE  file.id   IS 'id';
COMMENT ON COLUMN file.path IS 'путь к файлу';
COMMENT ON COLUMN file.name IS 'имя файла';
COMMENT ON COLUMN file.ext  IS 'расширение';
COMMENT ON COLUMN file.size IS 'размер';


-- таблица реквизитов
CREATE TABLE official (
    id            SERIAL,
    id_file       INTEGER REFERENCES file(id),
    name          VARCHAR(128) NOT NULL,
    address       VARCHAR(4096),
    regaddress    VARCHAR(4096),
    phone         VARCHAR(128),
    email         VARCHAR(128),
    bank          VARCHAR(128),
    account       CHAR(20),
	bank_account  CHAR(20),
    bik           CHAR(9),
    taxcode       VARCHAR(12) UNIQUE,
    taxreasoncode CHAR(9),
    regcode       CHAR(13),
    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE, INSERT ON TABLE official TO @@DBUSER@@;

COMMENT ON TABLE  official               IS 'реквизиты торговой точки или сети';
COMMENT ON COLUMN official.id            IS 'id';
COMMENT ON COLUMN official.id_file       IS 'логотип';
COMMENT ON COLUMN official.name          IS 'название компании';
COMMENT ON COLUMN official.address       IS 'фактический адрес';
COMMENT ON COLUMN official.regaddress    IS 'юридический адрес';
COMMENT ON COLUMN official.phone         IS 'телефон';
COMMENT ON COLUMN official.email         IS 'адрес электронной почты';
COMMENT ON COLUMN official.bank          IS 'наименование банка';
COMMENT ON COLUMN official.account       IS 'номер расчетного счета';
COMMENT ON COLUMN official.bank_account  IS 'номер корреспондентского счета';
COMMENT ON COLUMN official.bik           IS 'БИК';
COMMENT ON COLUMN official.taxcode       IS 'ИНН';
COMMENT ON COLUMN official.taxreasoncode IS 'КПП';
COMMENT ON COLUMN official.regcode       IS 'ОГРН';


COMMIT;