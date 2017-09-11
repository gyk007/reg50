-- Товары
-- step 0021
-- class: ALKO::Catalog::Property::Propdata

BEGIN;

-- таблица идентификационных данных для движка свойств
CREATE TABLE propdata (
        id_propgroup INTEGER,
        n_property   INTEGER,
        extra        VARCHAR(64),
        description  VARCHAR(1024),

        FOREIGN KEY (id_propgroup, n_property) REFERENCES property (id_propgroup, n),
        PRIMARY KEY (id_propgroup, n_property, extra)
);

GRANT SELECT, UPDATE, INSERT ON TABLE    propdata TO @@DBUSER@@;

COMMENT ON TABLE  propdata               IS 'идентификационные данные для движка свойств';
COMMENT ON COLUMN propdata.id_propgroup  IS 'группа свойств';
COMMENT ON COLUMN propdata.n_property    IS 'номер свойства в группе';
COMMENT ON COLUMN propdata.extra         IS 'идентификационная строка';
COMMENT ON COLUMN propdata.description   IS 'описание';


-- добавляем идентификационную строку для свойства 'Made in'
INSERT INTO propdata (id_propgroup, n_property, extra, description) VALUES (1, 7, 'made_in', 'Identification string for the property "Made in"');

COMMIT;