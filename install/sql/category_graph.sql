-- Дерево категорий
-- step 0003
-- class: ALKO::Catalog::Category::Graph
-- направленный граф


BEGIN;


CREATE TABLE category_graph (
	top   INTEGER NOT NULL REFERENCES category(id) ON UPDATE CASCADE,
	down  INTEGER NOT NULL UNIQUE REFERENCES category(id) ON UPDATE CASCADE, -- узел может иметь только одного родителя
	sortn INTEGER NOT NULL,
	face  VARCHAR(256),
	
	CONSTRAINT ichild UNIQUE (down, sortn), -- позиция внутри родителя уникальна
        PRIMARY KEY (top, down)
);

GRANT SELECT, UPDATE, INSERT ON TABLE category_graph TO @@DBUSER@@;

COMMENT ON TABLE  category_graph       IS 'дерево категорий';
COMMENT ON COLUMN category_graph.top   IS 'родитель';
COMMENT ON COLUMN category_graph.down  IS 'потомок; родитель может быть только один';
COMMENT ON COLUMN category_graph.sortn IS 'индекс положения внутри родителя; считается с 1';
COMMENT ON COLUMN category_graph.face  IS 'имя категории, выводимое в дереве; переопределяет имя, хранимое в самой категории';

-- Invisible root
INSERT INTO category_graph VALUES (0, 0, 0, null);

CREATE INDEX ON category_graph (sortn); -- чтобы пушить в конец списка сиблингов при построении
                                        -- дерева, ребра вытаскиваются в порядке расположения потомков в родителе


COMMIT;
