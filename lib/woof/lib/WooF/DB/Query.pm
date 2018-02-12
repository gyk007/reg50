package WooF::DB::Query;
use base qw / WooF::Object /;

=begin nd
Class: WooF::DB::Query
	Конструктор запросов.

	Позволяет дополнять запросы.

	Бывает полезно, когда в зависимости от условий в коде нужно изменить условия выборки из базы данных.
	Формат запроса имеет специальный вид. См. <WooF::DB::Query::new ()>
=cut

use v5.12.0;

use strict;
use warnings;
no if $] >= 5.018, warnings => 'experimental::smartmatch';
use utf8;

use WooF::Error;
use WooF::Util;

=begin nd
Variable: my %Attribute
	Члены класса:
	body   - Первая половина SQL до WHERE
	limit  - Условие для LIMIT
	offset - Условие для OFFSET
	ph     - Ссылка на массив с полями для проверки в WHERE
	sort   - Условия для сортировки
	val    - Ссылка на массив с проверяемыми значениями
	where  - Вторая половина SQL после WHERE
=cut
my %Attribute = (
	body   => undef,
	limit  => undef,
	offset => undef,
	ph     => {mode => 'read', default => []},
	sort   => undef,
	val    => {mode => 'read', default => []},
	where  => undef,
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.

Returns:
	Ссылку на хеш.
=cut
sub Attribute { \%Attribute }

=begin nd
Constructor: new ($q)
	Парсит запрос.

	Выделяет из запроса выражение, стоящее после 'WHERE' (обязательно большими буквами), и запоминает
	атрибуты body и where заполняются с помощью SQL, если он был передан конструктору.
	Если в этом SQL присутствует ключевое слово WHERE, то заполняются оба атрибута. Иначе - только body.
	Остальным атрибутам значения присваиваются в методе parse_clause.
	Этот класс умеет парсить только простые запросы.

	Лидирующая часть хранится как есть. Пока.

Parameters:
	$q - строка запроса

Returns:
	Экземпляр запроса, если в процессе парсинга не было ошибок.
=cut
sub new {
	my ($class, $q) = @_;

	my $self = $class->SUPER::new;

	if ($q) {
		$q =~ s/\s+/ /go;
		@{$self}{qw/ body where /} = split 'WHERE', $q, 2;
	}

	$self;
}

=begin nd
Method: parse_clause ($clause)
	На основании упакованного хеша условий (в WHERE) подготовить плейсхолдеры и бинды для SQL-запроса.

	Метод может вызываться как метод экземпляра, так и метод класса.

Parameters:
	$clause - ссылка на массив в который упакован хэш с условиями выборки.

	Правила преобразования хэша в условия для SQL.
	Каждая пара ключ-значение в этом хэше добавляет новое условие в данные для последующего SQL-запроса.
	При этом возможны три типа значений:
	скаляр
	ссылка на массив
	ссылка на хэш

	1) Значение - скаляр
	В общем случае, пара со скаляром в качестве значения задаёт условие на поиск определённого значения.
	Например, описываемый метод подготовит данные для преобразования вызова
	WooF::Order::Request->Get( id => 67 );
	в следующий SQL запрос:
	SELECT * FROM request WHERE id = 67;

	Аналогичным образом, в случае вызова
	WooF::Order::Request->All( status => 'done' );
	описываемый метод подготовит данные для
	SELECT * FROM request WHERE status = 'done';

	Значение undef интерпретируется как поиск нулевого значения в базе данных.
	Например,
	WooF::Order::Request->Get( id => undef );
	будет интерпретироваться как
	SELECT * FROM request WHERE id IS NULL;

	2) Значение - ссылка на массив.
	Описываемый метод будет готовить данные для SQL-запроса, где ключ равняется одному из перечисленных значений.

	Например,
	WooF::Order::Request->All( status => ['cancel', 'done'] );
	будет интерпретирован как
	SELECT * FROM request WHERE status IN ('cancel', 'done');

	WooF::Order::Request->All( status => [['cancel', 'done']] );
	будет интерпретирован как
	SELECT * FROM request WHERE status NOT IN ('cancel', 'done');

	3) Значение - ссылка на хэш
	Описываемый метод готовит данные для условия с операцией сравнения. При этом ключ в этом хэше - операнд, значение - скаляр для сравнения.

	Например,
	WooF::Order::Request->All( ctime => {'>=', '"2015-10-19 12:00:00"'} );
	будет интерпретирован как
	SELECT * FROM request WHERE ctime >= '2015-10-19 12:00:00';

	Если дана ссылка на пустой хэш, то описываемый метод готовит данные для поиска по ненулевым значениям.
	Например,
	WooF::Order::Request->All( status => {} );
	будет интерпретирован как
	SELECT * FROM request WHERE status IS NOT NULL;

	Контрольный пример:
	WooF::Order::Request->Get( id => 67, ctime => {'>=', '"2015-10-19 12:00:00"'} );
	будет интерпретирован как поиск заказа с id = 67 при условии что он был сделан не ранее полудня 19 октября 2015 года.

	Специальные аргументы для метода All. Используются для постраничного вывода больших массивов.
	OFFSET - Смещение перед выборкой. Осуществляет пропуск уже пролистанных страниц.
	LIMIT  - Максимальное количество извлекаемых записей. Соответствует размеру страницы.
	ORDER  - Сортировка записей перед выбором. Содержит ссылку на массив из условий сортировки.
	Например, ORDER => ['id, attr1 DESC', 'attr2, attr3 ASC']

	Пример выборки
	WooF::HTTPRequest->All(ctime => {'>=', '"2015-10-19 12:00:00"'}, OFFSET => 40, LIMIT => 20, ORDER => ['id DESC']);
	Находит в таблице httprequest записи, созданные после 19 октября 2015 года, сортирует их в порядке убывания id, затем из полученного массива передаёт записи с 41-й по 60-ю.

Returns:
	Экземпляр запроса, если в процессе парсинга не было ошибок.
=cut
sub parse_clause {
	my ($self, $clause) = @_;
	my $in = expose_hashes $clause;

	#my (@ph, @val);          # плейсхолдеры и значения
	while (my ($k, $v) = each %$in) {
		if ($k ~~ ['ORDER', 'OFFSET', 'LIMIT']) {
			$self->{lc $k} = $v;
		} else {
			unless (defined $v) {
				push @{$self->{ph}}, "$k IS NULL ";
			} elsif (ref $v eq 'ARRAY') {
				my $not = '';
				if (ref $v->[0] eq 'ARRAY') {
					$v = shift @$v;
					$not = 'NOT';
				}
				if (@$v) {
					my @qsign = split '', '?' x @$v;
					{
						local $" = ', ';
						push @{$self->{ph}}, "$k $not IN (@qsign)";
					}
					push @{$self->{val}}, ($k => $_) for @$v;
				} else {
					push @{$self->{ph}}, "$not FALSE";
				}
			} elsif (ref $v eq 'HASH') {
				my ($oper, $value) = %$v;
				if ($value) {
					push @{$self->{val}}, ($k => $value);
					push @{$self->{ph}}, "$k $oper ?";
				} else {
					push @{$self->{ph}}, "$k IS NOT NULL ";
				}
			} else {
				push @{$self->{val}}, ($k => $v);
				push @{$self->{ph}}, "$k = ?";
			}
		}
	}

	$self->{where} .= join ' AND ', @{$self->{ph}} if @{$self->{ph}};

	$self;
}

=begin nd
Method: parse_expand ($parents, $prev, $expand, $node)
	Получить строку джоинов под смежные экемпляры.

	Метод предназначен для вызова из слоя объектной модели, и не должен
	использоваться пользовательским кодом напрямую. Метод довольно тяжелый,
	в том числе, и за счет большого количества параметров.

	Метод использует рекурсию. В точке внешнего вызова код должен выглядеть следующим образом:
(start code)
my $ext_join = WooF::DB::Query->parse_expand(
	[],
	{
		class => $class,
		table => 'lasts',
		rc => '',
		init => 1,
		joined_tbls => undef,
	},
	[dstcustomer => ['avatar'], dstdriver => ['avatar']],
	{table => 'lasts', alias => undef, class => $class, extend => undef, parent => undef}
);
(end)
	Первый аргумент, стек, пуст, поскольку при первом вызове JOIN'ов еще нет. Но если надо
	прицепиться к уже существующему джоину, то можно стек заполнить вручную. Пока таких примеров нет,
	но принципиально они возможны, хотя представляют из себя нетривиальную задачу.

	Второй аргумент, представляющий структуру предыдущего элемента, должен содержать имя класса, соответствующее
	той таблице, с которой начинается джоин.

	Имя таблицы может не соответствовать реальной таблицы в базе данных, а представлять из себя псевдоним,
	используемый в запросе. Это та таблица, с которой начинается джоин.

	init должен быть установлен в true, чтобы именно эта первоначальная структура стала результатом выполнения метода.

	joined_tbls обычно должно быть пусто, если только в джоине не используется селф-джоин с уже используемыми ранее
	в запросе таблицами.

	Третий аргумент, $expand, в точности соответствует структуре EXPAND.

	Четвертый, последний элемент, практически полностью соответствует второму.
	В будущем, вероятно, можно будет их объединить.

Parameters:
	$parents - стек вызовов, представленный служебными структурами, аналогичными тем,
	           что соответствуют второму аргументу $prev
	$prev    - предыдушая структура дерева разбора.
	$expand  - еще не разобранная часть дерева, представленная в EXPAND.
	$node    - нода заполняемая на данном шаге.

Returns:
	Структуру из второго аргумента, в члене rc которого содержится строка джоинов.
=cut
sub parse_expand {
	my ($class, $parents, $prev, $expand, $node) = @_;
	$prev = \$_[2];
	$node = \$_[4];

	if (ref $expand eq 'ARRAY') {
		push @$parents, $$prev;

		my $curnode = {parent => $$node};

		$class->parse_expand($parents, $$prev, $_, $curnode) for @$expand;

		unless ($parents->[-1]{init}) {
			my $stale = pop @$parents;
			my $parent = $parents->[-1];

			$parent->{$_} = $stale->{$_} for qw/ rc joined_tbls /;
		}
	} else {
		my $parent = $parents->[-1];
		my $pclass = $parent->{class};
		my $xclass = $pclass->Attribute->{$expand}{extern};

		my $parent_tbl = $parent->{table} || $pclass->Table;
		my $module = $xclass;
		$module =~ s!::!/!g;
		$module .= '.pm';
		require $module or warn "OBJECT: Can't load xclass";
		my $joined_tbl = $xclass->Table;

		my $alias = '';
		if ((my $n = ++$parent->{joined_tbls}{$joined_tbl}{n}) > 1) {
			$alias = $joined_tbl . "_$n";
		}

		my $joined_name = $alias || $joined_tbl;
		$parent->{rc} .= "LEFT JOIN $joined_tbl $alias ON $parent_tbl.$expand = $joined_name.id ";

		$$prev = {class => $xclass, table => undef, rc => $parent->{rc}, init => 0, joined_tbls => $parent->{joined_tbls}};
		$$prev->{joined_tbls}{$joined_tbl}{class} = $$prev->{class};

		if (defined $$node->{table}) {
			my $curnode = {
				parent => $$node->{parent},
				table  => $joined_tbl,
				alias  => $alias,
				class  => $xclass,
				extend => undef,
				name   => $expand,
			};
			$$node->{parent}{extend}{$expand} = $curnode;
			$$node = $curnode;
		} else {
			$$node->{table}  = $joined_tbl;
			$$node->{alias}  = $alias;
			$$node->{class}  = $xclass;
			$$node->{extend} = undef;
			$$node->{name}   = $expand;

			$$node->{parent}{extend}{$expand} = $$node;
		}

		return;
	}

	$parents->[-1];
}

=begin nd
Method: print ( )
	Сформировать окончательный запрос.

Returns:
	Строку запроса.
=cut
sub print {
	my $self = shift;

	my $query = $self->{body};
	$query .= ' WHERE ' . $self->{where}                  if $self->{where};
	$query .= ' ORDER BY ' . join(',', @{$self->{order}}) if $self->{order};
	$query .= ' OFFSET ' . $self->{offset}                if $self->{offset};
	$query .= ' LIMIT ' . $self->{limit}                  if $self->{limit};

	$query;
}
=begin
Method: val
	Геттер для val

Returns:
	Массив или ссылку на массив в зависимости от контекста
=cut
sub val {
	my $self = shift;

	wantarray ? @{$self->{val}} : $self->{val};
}

=begin nd
Method: where ($condition)
	Приклеить условие в конец запроса, добавив перед ним пробел.

	Безопасно только в случаях, когда приклеенное where допустимо.

Parameters:
	$condition - строка с условием в том виде, в каком должна попасть в запрос.
=cut
sub where {
	my ($self, $condition) = @_;

	$self->{where} .= " $condition";
}

1;
