-- Товары
-- step 0021
-- class: ALKO::Catalog::Property::Propdata

BEGIN;

-- таблица идентификационных данных для движка свойств
CREATE TABLE propdata (
        id_propgroup INTEGER,
        n_property   INTEGER,
        extra        VARCHAR(64),
        n            INTEGER,
        description  VARCHAR(1024),

        FOREIGN KEY (id_propgroup, n_property) REFERENCES property (id_propgroup, n),
        PRIMARY KEY (id_propgroup, n_property, extra, n)
);

GRANT SELECT, UPDATE, INSERT ON TABLE    propdata TO @@DBUSER@@;

COMMENT ON TABLE  propdata               IS 'идентификационные данные для движка свойств';
COMMENT ON COLUMN propdata.id_propgroup  IS 'группа свойств';
COMMENT ON COLUMN propdata.n_property    IS 'номер свойства в группе';
COMMENT ON COLUMN propdata.extra         IS 'идентификационная строка';
COMMENT ON COLUMN propdata.n             IS 'порядковый номер';
COMMENT ON COLUMN propdata.description   IS 'описание';


-- добавляем идентификационные строку для свойства  типа unitable
INSERT INTO propdata (id_propgroup, n_property, extra, n, description) VALUES (1, 7, 'made_in',      1, 'Identification string for the property "Made in"');
INSERT INTO propdata (id_propgroup, n_property, extra, n, description) VALUES (1, 2, 'brand',        1, 'Identification string for the property "Brand"');
INSERT INTO propdata (id_propgroup, n_property, extra, n, description) VALUES (1, 3, 'manufacturer', 1, 'Identification string for the property "Manufacturer"');


COMMIT;