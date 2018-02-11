-- Заказ
-- step 017
-- class: ALKO::News

BEGIN;


-- таблица новостей
CREATE TABLE mob_news  (
    id               SERIAL,
    title            VARCHAR(512),
    text             TEXT,
    description      TEXT,
    ctime            TIMESTAMP(6) WITH TIME ZONE,
    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE mob_news TO @@DBUSER@@;

COMMENT ON TABLE  mob_news             IS 'новость';
COMMENT ON COLUMN mob_news.id          IS 'id';
COMMENT ON COLUMN mob_news.title       IS 'pагаловок';
COMMENT ON COLUMN mob_news.text        IS 'текст новости';
COMMENT ON COLUMN mob_news.description IS 'краткое описание';
COMMENT ON COLUMN mob_news.ctime       IS 'дата создания';


-- таблица представителей
CREATE TABLE mob_manager (
    id       SERIAL,
    password VARCHAR(128) NOT NULL,
    email    VARCHAR(128) NOT NULL UNIQUE,
    name     VARCHAR(128),
    phone    VARCHAR(128),
    firebase VARCHAR(512),
    PRIMARY KEY (id)
); 

GRANT SELECT, UPDATE, INSERT ON TABLE mob_manager TO @@DBUSER@@;

COMMENT ON TABLE  mob_manager           IS 'торговый представитель';
COMMENT ON COLUMN mob_manager.id        IS 'id';
COMMENT ON COLUMN mob_manager.password  IS 'пароль';
COMMENT ON COLUMN mob_manager.email     IS 'адрес электронной почты. Логин';
COMMENT ON COLUMN mob_manager.name      IS 'имя';
COMMENT ON COLUMN mob_manager.phone     IS 'телефон';

ALTER TABLE session ADD column id_mob_manager INTEGER REFERENCES mob_manager(id);

-- таблица связь новости и представителя
CREATE TABLE mob_news_manager (
    id_mob_news     INTEGER NOT NULL REFERENCES mob_news(id),
    id_mob_manager  INTEGER NOT NULL REFERENCES mob_manager(id),
    PRIMARY KEY (id_mob_news, id_mob_manager)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE mob_news_manager TO @@DBUSER@@;

COMMENT ON TABLE  mob_news_manager                IS 'связь новость представитель';
COMMENT ON COLUMN mob_news_manager.id_mob_news    IS 'новость';
COMMENT ON COLUMN mob_news_manager.id_mob_manager IS 'представитель';


COMMIT;