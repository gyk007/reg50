-- Товары
-- step 0021
-- class: ALKO::Catalog::Property::Propdata


BEGIN;


CREATE TABLE propdata (
        id_propgroup INTEGER NOT NULL property(id_propgroup),
        n_property   INTEGER NOT NULL property(n),
        n            INTEGER NOT NULL,
        extra        VARCHAR(1024) NOT NULL,

        PRIMARY KEY (id_propgroup, n_property, n)
);

GRANT SELECT, UPDATE         ON SEQUENCE propdata TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    propdata TO @@DBUSER@@;

COMMENT ON TABLE  propdata               IS 'идентификационные данные для движка свойсв';
COMMENT ON COLUMN propdata.id_propgroup  IS 'группа свойств';
COMMENT ON COLUMN propdata.n_property    IS 'номер свойсва в группе';
COMMENT ON COLUMN propdata.n             IS 'номер по порядку';
COMMENT ON COLUMN propdata.extra         IS 'идентификационная строка';


COMMIT;