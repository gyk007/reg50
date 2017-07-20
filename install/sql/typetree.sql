-- Дерево типов свойств
-- step 0009
-- class:
--    ALKO::Catalog::Property::Type::Graph
--    ALKO::Catalog::Property::Type::Matrix
--    ALKO::Catalog::Property::Type::Matrix::Unit
--    ALKO::Catalog::Property::Type::Matrix::Value
--    ALKO::Catalog::Property::Type::Matrix::Node

BEGIN;


-- Предварительно очищаем все типы.
-- Данные таблицы не предназначены для заполнения пользователями,
-- и имеют определенные программистом кортежи.
DELETE FROM propvalue;
DELETE FROM paramvalue;
DELETE FROM propparam;
DELETE FROM property;
DELETE FROM proptype;
SELECT setval('proptype_id_seq', 1, false);

-- дерево типов свойств
CREATE TABLE proptype_graph (
	top  INTEGER REFERENCES proptype(id) ON UPDATE CASCADE,
	down INTEGER REFERENCES proptype(id) ON UPDATE CASCADE UNIQUE,
	PRIMARY KEY (top, down)
);

GRANT SELECT, UPDATE, INSERT ON TABLE proptype_graph TO @@DBUSER@@;

COMMENT ON TABLE  proptype_graph      IS 'дерево типов свойств';
COMMENT ON COLUMN proptype_graph.top  IS 'родитель';
COMMENT ON COLUMN proptype_graph.down IS 'потомок';

-- Невидимый корень
INSERT INTO proptype VALUES (0, 'root', 'Invisible ROOT', NULL);
INSERT INTO proptype_graph VALUES (0, 0);


-- измерения матрицы
CREATE TABLE matrixunit (
	top         INTEGER,
	down        INTEGER,
	n           INTEGER,
	name        VARCHAR(256),
	description VARCHAR(4096),
	FOREIGN KEY (top, down) REFERENCES proptype_graph(top, down),
	PRIMARY KEY (top, down, n)
);

GRANT SELECT, UPDATE, INSERT ON TABLE matrixunit TO @@DBUSER@@;

COMMENT ON TABLE  matrixunit             IS 'Измерения матрицы выбора в ноде дерева типов свойств';
COMMENT ON COLUMN matrixunit.top         IS 'родитель в дереве типов свойств; часть внешнего ключа';
COMMENT ON COLUMN matrixunit.down        IS 'потомок в дереве типов свойств; часть внешнего ключа';
COMMENT ON COLUMN matrixunit.n           IS 'порядковый номер измерения внтри ноды дерева типов';
COMMENT ON COLUMN matrixunit.name        IS 'наименование';
COMMENT ON COLUMN matrixunit.description IS 'описание';


-- имеющиеся значения для каждого измерения матрицы
CREATE TABLE unitvalue (
	top    INTEGER,
	down   INTEGER,
	n_unit INTEGER,
	n      INTEGER,
	val    VARCHAR(256),
	FOREIGN KEY (top, down, n_unit) REFERENCES matrixunit(top, down, n),
	UNIQUE (top, down, n_unit, n, val),
	PRIMARY KEY (top, down, n_unit, n)
);

GRANT SELECT, UPDATE, INSERT ON TABLE unitvalue TO @@DBUSER@@;

COMMENT ON TABLE  unitvalue        IS 'допустимые значения конкретного измерения конкретной матрицы выбора';
COMMENT ON COLUMN unitvalue.top    IS 'родитель; часть идентификатора измерения';
COMMENT ON COLUMN unitvalue.down   IS 'потомок; часть идентификатора измерения';
COMMENT ON COLUMN unitvalue.n_unit IS 'номер измерения; часть идентификатора измерения';
COMMENT ON COLUMN unitvalue.n      IS 'порядковый номер значения внутри измерения';
COMMENT ON COLUMN unitvalue.val    IS 'само значение; одно среди многих значений измерения';


-- нода матрицы
CREATE TABLE matrix (
	top  INTEGER,
	down INTEGER,
	n    INTEGER,
	nextdown INTEGER REFERENCES proptype_graph(down),
	FOREIGN KEY (top, down) REFERENCES proptype_graph (top, down),
	PRIMARY KEY (top, down, n)
);

GRANT SELECT, UPDATE, INSERT ON TABLE matrix TO @@DBUSER@@;

COMMENT ON TABLE  matrix          IS 'нода дерева типов свойств, определяет проход вниз по дереву; сама нода; ее определение находится в matrixnode';
COMMENT ON COLUMN matrix.top      IS 'родитель; часть идентификатора ноды дерева';
COMMENT ON COLUMN matrix.down     IS 'потомок; часть идентификатора ноды дерева';
COMMENT ON COLUMN matrix.n        IS 'порядковый номер ноды в конкретной матрице; определяется n-мерной совокупнсотью значений измерений в matrixnode';
COMMENT ON COLUMN matrix.nextdown IS 'потомок в дереве типов, на который осуществляется проход через данную ноду';


-- определение ноды матрицы
CREATE TABLE matrixnode (
	top     INTEGER,
	down    INTEGER,
	n       INTEGER,
	n_unit  INTEGER,
	n_value INTEGER,
	FOREIGN KEY (top, down, n)               REFERENCES matrix(top, down, n),
	FOREIGN KEY (top, down, n_unit, n_value) REFERENCES unitvalue(top, down, n_unit, n),
	PRIMARY KEY (top, down, n, n_unit, n_value)
);

GRANT SELECT, UPDATE, INSERT ON TABLE matrixnode TO @@DBUSER@@;

COMMENT ON TABLE  matrixnode         IS 'определение ноды матрицы набором значений каждого измерения';
COMMENT ON COLUMN matrixnode.top     IS 'родитель; часть идентификатора ноды матрицы';
COMMENT ON COLUMN matrixnode.down    IS 'потомок; часть идентификатора ноды матрицы';
COMMENT ON COLUMN matrixnode.n       IS 'номер ноды в матрице; часть идентификатора ноды матрицы';
COMMENT ON COLUMN matrixnode.n_unit  IS 'номер измерения матрицы';
COMMENT ON COLUMN matrixnode.n_value IS 'номер значения в измерении матрицы';


COMMIT;
