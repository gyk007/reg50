-- Заказ
-- step 017
-- class: ALKO::News

BEGIN;


-- таблица тегов для новостей (группы)
CREATE TABLE mob_news_tag  (
    id               SERIAL,
    name             VARCHAR(256),
    description      VARCHAR(512),
    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE mob_news_tag TO @@DBUSER@@;

COMMENT ON TABLE  mob_news_tag              IS 'тег для новости';
COMMENT ON COLUMN mob_news_tag.id           IS 'id';
COMMENT ON COLUMN mob_news_tag.name         IS 'название';
COMMENT ON COLUMN mob_news_tag.description  IS 'описание';


-- таблица связь новости и тега
CREATE TABLE mob_news_teg_ref (
    id_mob_news      INTEGER NOT NULL REFERENCES mob_news(id),
    id_mob_news_tag  INTEGER NOT NULL REFERENCES mob_news_tag(id),
    PRIMARY KEY (id_mob_news, id_mob_news_tag)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE mob_news_teg_ref TO @@DBUSER@@;

COMMENT ON TABLE  mob_news_teg_ref                 IS 'ссылка на тег для новости';
COMMENT ON COLUMN mob_news_teg_ref.id_mob_news     IS 'id новости';
COMMENT ON COLUMN mob_news_teg_ref.id_mob_news_tag IS 'id тега';


-- таблица связь менеджера и тега
CREATE TABLE mob_manager_teg_ref (
    id_mob_manager   INTEGER NOT NULL REFERENCES mob_manager(id),
    id_mob_news_tag  INTEGER NOT NULL REFERENCES mob_news_tag(id),
    PRIMARY KEY (id_mob_manager, id_mob_news_tag)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE mob_manager_teg_ref TO @@DBUSER@@;

COMMENT ON TABLE  mob_manager_teg_ref                 IS 'ссылка на тег для новости';
COMMENT ON COLUMN mob_manager_teg_ref.id_mob_manager  IS 'id менеджера';
COMMENT ON COLUMN mob_manager_teg_ref.id_mob_news_tag IS 'id тега';


COMMIT;