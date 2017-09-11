-- Товары
-- step 0021
-- class: ALKO::Catalog::Property::Propdata


BEGIN;


CREATE TABLE propdata (
        id_propgroup INTEGER property(id_propgroup),
        n_property   INTEGER property(n),
        extra        VARCHAR(1024),
        description  VARCHAR(1024),

        PRIMARY KEY (id_propgroup, n_property, extra)
);

GRANT SELECT, UPDATE         ON SEQUENCE propdata TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    propdata TO @@DBUSER@@;

COMMENT ON TABLE  propdata               IS 'идентификационные данные для движка свойсв';
COMMENT ON COLUMN propdata.id_propgroup  IS 'группа свойств';
COMMENT ON COLUMN propdata.n_property    IS 'номер свойсва в группе';
COMMENT ON COLUMN propdata.extra         IS 'идентификационная строка';
COMMENT ON COLUMN propdata.description   IS 'описание';


COMMIT;