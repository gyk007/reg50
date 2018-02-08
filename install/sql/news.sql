-- Заказ
-- step 017
-- class: ALKO::News

BEGIN;


-- таблица новостей
CREATE TABLE news  (
    id               SERIAL,
    title            VARCHAR(512),
    text             TEXT,
    ctime            TIMESTAMP(6) WITH TIME ZONE,
    PRIMARY KEY (id)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE news TO @@DBUSER@@;

COMMENT ON TABLE  news        IS 'новость';
COMMENT ON COLUMN news.id     IS 'id';
COMMENT ON COLUMN news.title  IS 'pагаловок';
COMMENT ON COLUMN news.text   IS 'текст новости';
COMMENT ON COLUMN news.ctime  IS 'дата создания';

-- таблица связь новости и представителя
CREATE TABLE news_merchant (
    id_news     INTEGER NOT NULL REFERENCES news(id),
    id_merchant INTEGER NOT NULL REFERENCES merchant(id),
    PRIMARY KEY (id_news, id_merchant)
);

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE news_merchant TO @@DBUSER@@;

COMMENT ON TABLE  news_merchant             IS 'документ в заказе';
COMMENT ON COLUMN news_merchant.id_news     IS 'новость';
COMMENT ON COLUMN news_merchant.id_merchant IS 'представитель';


COMMIT;