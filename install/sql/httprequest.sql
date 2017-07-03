-- Таблица HTTP-запросов
-- step 0001
-- class: WooF::HTTPRequest::PSGI


BEGIN;


CREATE TABLE httprequest (
        id      SERIAL,
        headers VARCHAR(4096),
        ip      INET,
        method  VARCHAR(128),
        path    VARCHAR(4096),
        qstring VARCHAR(4096),
        referer VARCHAR(4096),
        tik     TIMESTAMP(6) WITH TIME ZONE,
        tok     TIMESTAMP(6) WITH TIME ZONE,

        PRIMARY KEY (id)
);

GRANT SELECT, UPDATE         ON SEQUENCE httprequest_id_seq TO @@DBUSER@@;
GRANT SELECT, UPDATE, INSERT ON TABLE    httprequest        TO @@DBUSER@@;

COMMENT ON TABLE  httprequest         IS 'HTTP-запросы';
COMMENT ON COLUMN httprequest.id      IS 'id';
COMMENT ON COLUMN httprequest.headers IS 'Заголовки клиента';
COMMENT ON COLUMN httprequest.ip      IS 'IP-адрес клиента';
COMMENT ON COLUMN httprequest.method  IS 'Метод, запрошенный клиентом (GET/POST)';
COMMENT ON COLUMN httprequest.path    IS 'Путь как часть урла';
COMMENT ON COLUMN httprequest.qstring IS 'Query String';
COMMENT ON COLUMN httprequest.referer IS 'Отдельно заголовок REFERER';
COMMENT ON COLUMN httprequest.tik     IS 'Врема начала обработки запроса скриптом';
COMMENT ON COLUMN httprequest.tok     IS 'Время окончания обработки запроса скриптом';


COMMIT;
