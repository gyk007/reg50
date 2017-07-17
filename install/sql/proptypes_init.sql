-- Введение первых типов свойств: "скалярное целое" и "единичный выбор из таблицы"
-- step 0009

BEGIN;


-- Добавляем данные под проходной тип свойства "Скаляр"
-- добавляем тип
INSERT INTO proptype (id, name, description, valtype) VALUES (default, 'Scalar', 'Single value', null);  -- id=1
-- тип добавляем в дерево типов
INSERT INTO proptype_graph (top, down) VALUES (0, 1);
-- корневому типу добавляем первое измерение матрицы
INSERT INTO matrixunit (top, down, n, name, description) VALUES (0, 0, 1, 'Property type', 'Main selection');
-- добввляем измерению возможные значения
INSERT INTO unitvalue (top, down, n_unit, n, val) VALUES (0, 0, 1, 1, 'Scalar');
-- добавляем в матрицу ноду
INSERT INTO matrix (top, down, n, nextdown) VALUES (0, 0, 1, 1);
-- определение ноды
INSERT INTO matrixnode (top, down, n, n_unit, n_value) VALUES (0, 0, 1, 1, 1);


-- Добавляем данные под конечный тип свойства "Целое" внутри "Скаляра"
-- добавляем тип
INSERT INTO proptype (id, name, description, valtype) VALUES (default, 'Integer', 'Integer number', 'val_int');  -- id=2
-- тип добавляем в дерево типов
INSERT INTO proptype_graph (top, down) VALUES (1, 2);
-- типу 'Scalar' добавляем первое измерение матрицы
INSERT INTO matrixunit (top, down, n, name, description) VALUES (0, 1, 1, 'Value Type', 'Type of stored value');
-- добввляем измерению возможные значения
INSERT INTO unitvalue (top, down, n_unit, n, val) VALUES (0, 1, 1, 1, 'Integer');
-- добавляем в матрицу ноду
INSERT INTO matrix (top, down, n, nextdown) VALUES (0, 1, 1, 2);
-- определение ноды
INSERT INTO matrixnode (top, down, n, n_unit, n_value) VALUES (0, 1, 1, 1, 1);


-- Добавляем данные под проходное свойство "Выбор из списка"
-- добавляем тип
INSERT INTO proptype (id, name, description, valtype) VALUES (default, 'Select', 'Select from list', null);  -- id=3
-- тип добавляем в дерево типов
INSERT INTO proptype_graph (top, down) VALUES (0, 3);
-- добввляем единственному измерению корня типов значение под "Выбор из списка"
INSERT INTO unitvalue (top, down, n_unit, n, val) VALUES (0, 0, 1, 2, 'Select from list');
-- добавляем в корневую матрицу ноду для прохода в "Выбор"
INSERT INTO matrix (top, down, n, nextdown) VALUES (0, 0, 2, 3);
-- определение ноды
INSERT INTO matrixnode (top, down, n, n_unit, n_value) VALUES (0, 0, 2, 1, 2);


-- Добавляем данные под конечный тип свойства "Единичный выбор из таблицы"
-- добавляем тип
INSERT INTO proptype (id, name, description, valtype) VALUES (default, 'Unique choice from table', 'Select from table single value', 'val_int');  -- id=4
-- тип добавляем в дерево типов
INSERT INTO proptype_graph (top, down) VALUES (3, 4);
-- типу 'Select' добавляем первое измерение матрицы - 'Множественность'
INSERT INTO matrixunit (top, down, n, name, description) VALUES (0, 3, 1, 'Multiple', 'Single- or Multi- choice');
-- добввляем измерению возможные значения
INSERT INTO unitvalue (top, down, n_unit, n, val) VALUES (0, 3, 1, 1, 'single');
INSERT INTO unitvalue (top, down, n_unit, n, val) VALUES (0, 3, 1, 2, 'multi');
-- типу 'Select' добавляем второе измерение матрицы - 'Источник данных'
INSERT INTO matrixunit (top, down, n, name, description) VALUES (0, 3, 2, 'Source', 'Source of Choice List');
-- добввляем измерению возможные значения
INSERT INTO unitvalue (top, down, n_unit, n, val) VALUES (0, 3, 2, 1, 'preset');
INSERT INTO unitvalue (top, down, n_unit, n, val) VALUES (0, 3, 2, 2, 'table');
-- добавляем в матрицу ноду для "единичного выбора из таблицы"; остальные три ноды (2х2 - 1 = 3) пока останутся неопределенными
INSERT INTO matrix (top, down, n, nextdown) VALUES (0, 3, 1, 4);
-- определение ноды в двух измерениях
INSERT INTO matrixnode (top, down, n, n_unit, n_value) VALUES (0, 3, 1, 1, 1);
INSERT INTO matrixnode (top, down, n, n_unit, n_value) VALUES (0, 3, 1, 2, 2);


COMMIT;
