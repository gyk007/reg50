package WooF::Object;
# use base qw / WooF Exporter /;
use base qw / WooF /;

=begin nd
Class: WooF::Object
	Базовый класс для любых объектно-ориентированных модулей.

	Каждый потомок должен определить хеш %Attribute, ключами которого являются имена членов класса,
	а значениями либо undef, либо ссылка на хеш с дополнительными параметрами для каждого атрибута.

	Дополнительными параметрами являются 'default', 'мode', 'type', 'extern', 'maps'.

	Значение для ключа 'default' станет значением по умолчанию конкретного члена класса при вызове конструктора или, например, метода класса <WooF::Object::Generate_Key ()>.
	Если вместо хеша с дополнительными параметрами использовано undef, дефолтным значением будет также undef.
	Если в атрибутах класса указано дефолтное значение, и при этом оно является ссылкой, то структура данных из такой ссылки будет скопирована,
	а не присвоена в качестве ссылки. Как правило, это то, что требуется.

	В дополнительном параметре 'mode' указывается режим доступа к члену класса:
	'read' - только чтение
	'write' - только запись
	'read/write' - чтение и запись
	undef - нет прав ни на чтение, ни на запись

	Если вместо хеша с дополнительными параметрами использовано undef, значением режима доступа будет также undef.
	То есть, ни чтение, ни запись не разрешены.

	Значениемя поля 'type' может быть 'cache' или 'key'.

	type => 'cache' позволяет задать поля, которые не будут сохраняться в базе данных. Это поля хранения временных вычисленных данных.

	type => 'key' определяет ключевое поле в том случае, когда оно не является внешним ключом другой сущности.

	Поле 'extern' содержит строку с именем класса, экземплярами которого представлены "расширенные" значения данного поля.
	Расширенные значения хранятся в специальном поле-хеше 'extend' экземпляра.

	Есть два случая обработки и представления расширенных экземпляров.

	Случай 'один-к-многим' со стороны многих и внешним ключом из главной таблицы.
	extern определен, но type не установлен в 'cache'.
	В самом члене класса хранится фактическое значение из базы, а в extend->{имя_атрибута} находится связанный экземпляр.
	Такая схема сейчас реализована тольо для метода <All_Fresh>.

	Случай 'многие-ко-многим'. 'extern' установлен и type=>'cache'. Сам атрибут имеет значение undef, а extend->{имя_атрибута}
	содержит коллекцию класса, указанного в extern.
	Такая схема на данный момент работает для метода <Get> и допускает единственный параметр-строку для 'expand', а основной класс
	должен быть потомком <WooF::Object::Simple>, то есть имеять первичным ключом атрибут 'id'.

	maps в случае многие-ко-многим определяет механизм формирования расширенного атрибута.

	В поле class указывается имя класса-связки, содержащего первичные ключи основного класса и связанного класса.

	В поле master должно быть указано имя атрибута внешнего ключа в классе-связки для основного класса, а в поле slave
	имя атрибута в классе-связки для связываемого класса.

	В поле set может задаваться хеш преобразования. Ключом хеша является поле-источник, атрибут класса-связки, из которого берется
	текущее значение. А значение хеша должно содержать имя атрибута назначения в связываемом классе, куда будет скопировано значение источника.
	Таким образом таблица-связка может содержать данные для заполнения отдельных полей экземпляров привязываемой коллекции.

> package MyClass;
>
> use parent 'WooF::Object';
>
>
> my %Attribute = (
>	attr1 => {
>		default => 25,
>		mode    => 'read/write',
>	},
> );
>
> # или
> my %Attribute = (
>	description => undef,
>	name        => undef,
>	products    => {
>		type => 'cache',
>		extern => 'ALKO::Catalog::Product',
>		maps => {
>			class  => 'ALKO::Catalog::Product::Link',
>			master => 'id_category',
>			slave  => 'id_product',
>			set    => {face => 'face_effective'},
>		},
>	},
>	visible     => undef,
> );
>
> sub Attribute { \%Attribute; }
>

	Естественно, получить доступ к члену любого класса можно откуда угодно непосредственно, разыменовав ссылку на хеш с атрибутами
>	my $val = $self->{attr_1};
>	$self->{attr_2} = $val;

	Но такая практика не приветствуется за пределами самого класса и его потомков.
	Вместо этого, к членам класса следует обращаться посредством методов доступа, что обеспечивает проверку прав на чтение/запись
>	# получение значение атрибута
>	my $val = $self->attr_1;
>
>	# установка значения атрибуту
>	$self->attr_2($val);
=cut

use 5.014;
use strict;
use warnings;

use Clone qw/ clone /;

use WooF::Object::Constants;
use WooF::Error;
use WooF::DB;
use WooF::Util;
use WooF::DB::Query;
use WooF::Object::Collection;
use WooF::Object::Key;
use WooF::Debug;
=begin nd
Variable: $AUTOLOAD
	Имя всплывшего метода
=cut
use vars qw/ $AUTOLOAD /;

=begin nd
Variable: my %Done
	Хеш, ключами которого являются уже встречавшиеся методы.
	После первого вызова метод должен уже быть сгенерирован в классе и его повторный вызова быть не должно.
=cut
my %Done;	# Хеш вызывавшихся методов. См. sub AUTOLOAD

=begin nd
Constant: READ
	метод чтения

Constant: WRITE
	метод записи
=cut
use constant {
	READ  => 'read',
	WRITE => 'write',
};

=begin nd
Constructor: new (NO_SYNC, @attrs)
	Конструктор устанавливает права на чтение\запись членам класса и
	переданные значения, а если их нет, то дефолтные, если указаны в описании хеша Attribute соответствующего класса.
	Если какой-либо из аргументов является ссылкой на экземпляр того же класса, то разыменовать его.

	Если первым аргументом указан флаг NO_SYNC, то это означает что создаваемый экземпляр класса не подлежит автоматическому сохранению после выхода из области видимости.
	Чтобы восстановить режим автоматического сохранения для этого экземпляра, необходимо вызвать для него метод Sync.

	Если в атрибутах класса указано дефолтное значение, и при этом оно является ссылкой, то структура данных из такой ссылки будет скопирована,
	а не присвоена в качестве ссылки. Как правило, это то, что требуется.

=cut
sub new {
	my $class = shift;

	my $nosync = shift if @_ and defined $_[0] and $_[0] eq NO_SYNC;

	my $in = expose_hashes [map ref $_ && ref $_ eq $class ? (%$_) : $_, @_];

	my $self = bless {}, $class;

	my $attr = $self->Attribute;
	while (my ($k, $v) = each %$attr) {
		if (exists $in->{$k}) {
			$self->{$k} = $in->{$k};
		} elsif (exists $v->{default}) {
			$self->{$k} = ref $v->{default} ? clone $v->{default} : $v->{default};
		} else {
			$self->{$k} = undef;
		}
	}

	$self->{STATE}  = OBJINIT;
	$self->{STATE} |= NOSYNC if $nosync;

	$self;
}

=begin nd
Method: _accessible ($attr, $mode)
	Преверка доступности члена класса на чтение/запись.

	Потомки должны определить в методе класса  'Attribute'.

Parameters:
	$attr - член класса
	$mode - доступ к члену класса
=cut
sub _accessible {
	my ($self, $attr, $mode) = @_;

	my $package = ref $self;
	my $access = $self->Attribute;

	return warn "Package $package does not have hash %Attribute" unless $access;

	return (
			exists $access->{$attr}
		and
			exists $access->{$attr}{mode}
		and
			defined $access->{$attr}{mode}
		and
			$access->{$attr}{mode} =~ $mode
		?
			1
		:
			undef
	);
}

=begin nd
Method: _access_r ($autoload)
	Метод доступа к атрибуту, имеющему право только на чтение.

Parameters:
	$autoload - полное имя метода

Returns:
	ссылку на метод.
=cut
sub _access_r {
	my ($self, $autoload) = @_;
	my $attr = $self->_get_method_name($autoload);

	sub {
		my $self = shift;

		return warn "OBJECT|ERR: Write access for $autoload denied by rules" if @_;

		my $Attribute = $self->Attribute->{$attr};

		if (exists $Attribute->{extern} and exists $Attribute->{type} and $Attribute->{type} eq 'cache') {
			return exists $self->{extend} && exists $self->{extend}{$attr} ? $self->{extend}{$attr} : undef;
		} else {
			return $self->{$attr};
		}
	};
}

=begin nd
Method: _access_rw ($autoload)
	Метод доступа к атрибуту, имеющему право и на запись и чтение.

Parameters:
	$autoload - полное имя метода

Returns:
	ссылку на метод
=cut
sub _access_rw {
	my ($self, $autoload) = @_;
	my $attr = $self->_get_method_name($autoload);

	sub {
		my $self = shift;
		my $Attribute = $self->Attribute->{$attr};

		if (@_) {
			my $value = shift;
			if (exists $Attribute->{extern} and exists $Attribute->{type} and $Attribute->{type} eq 'cache') {
				$self->{extend}{$attr} = $value;
			} else {
				$self->{$attr} = $value;

				if ($self->{STATE} & DWHLINK) {
					$self->{STATE} |= MODIFIED unless exists $Attribute->{type} and $Attribute->{type} eq 'cache';
				}
			}

			return $self;
		} else {
			if (exists $Attribute->{extern} and exists $Attribute->{type} and $Attribute->{type} eq 'cache') {
				return exists $self->{extend} && exists $self->{extend}{$attr} ? $self->{extend}{$attr} : undef;
			} else {
				return $self->{$attr};
			}
		}
	};
}

=begin nd
Method: _access_no ($autoload)
	Метод доступа к атрибуту, не имеющему прав ни на чтение, ни на запись.
	Генерируется ошибка OBJECT|ERR

Parameters:
	$autoload - полное имя метода

Returns:
	undef
=cut
sub _access_no {
	my (undef, $autoload) = splice @_;

	sub {
		return warn @_ > 1 ?
			  "OBJECT|ERR: Write access for $autoload denied by rules"
			: "OBJECT|ERR: Read  access for $autoload denied by rules";
	};

}

=begin nd
Method: _access_w ($autoload)
	Метод доступа к атрибуту, имеющему право только на запись.

Parameters:
	$autoload - полное имя метода

Returns:
	ссылку на метод.

=cut
sub _access_w {
	my ($self, $autoload) = @_;

	my $attr = $self->_get_method_name($autoload);

	sub {
		my $self = shift;

		return warn "OBJECT|ERR: Read access for $autoload denied by rules" unless @_;

		my $value = shift;

		my $Attribute = $self->Attribute->{$attr};
		if (exists $Attribute->{extern} and exists $Attribute->{type} and $Attribute->{type} eq 'cache') {
			$self->{extend}{$attr} = $value;
		} else {
			if ($self->{STATE} & DWHLINK) {
				$self->{STATE} |= MODIFIED unless exists $Attribute->{type} and $Attribute->{type} eq 'cache';
			}

			$self->{$attr} = $value;
		}

		$self;
	};
}

=begin nd
Method: All (@filter)
	Получить коллекцию экземпляров класса, удовлетворяющих условиям выбрки.
	Данный метод может вызываться и как метод класса, и как метод экземпляра.

	Замена и подстановка аргументов:

	SORT меняется на ORDER
	SORT => 'DEFAULT' - ORDER по первичным ключам
	Если установлен SLICEN, но не установлен SORT будет выполнен ORDER по первичным ключам

	SLICEN
	Метод убирает условие SLICEN заменяет его эквивалентными по функциональности ключами LIMIT и OFFSET.
	Возможные форматы ключа
	1) SLICEN => [size, pos] - заменяется на LIMIT => size, OFFSET => pos
	2) SLICEN => [size]      - заменяется на LIMIT => size. Эквивалентно 1) c OFFSET = 0
	3) SLICEN => size        - заменяется на LIMIT => size. Эквивалентно 2)
Parameters:
	@filter - условия выборки. Более подробно см. в описании к методу parse_clause в классе WooF::DB::Query

Returns:
	Все экземпляры класса, удовлетворяющие условиям выборки, упакованные в коллекцию.
=cut
sub All {
	my ($either, @filter) = @_;

	my $class = ref $either || $either;

	my $table = $class->Table;
	my $in = expose_hashes \@filter;

	if (exists $in->{SORT}) {
		$in->{ORDER} = $in->{SORT};
		$in->{ORDER} = $either->Sorted_keys if $in->{SORT} eq 'DEFAULT';
		delete $in->{SORT};
	}
	#  Заменить SLICEN эквивалентными по функциональности ключами
	if (exists $in->{SLICEN}) {
		my $slice = $in->{SLICEN};
		@{$in}{qw/ LIMIT OFFSET /} = ref $slice ? @$slice : $slice;
		$in->{ORDER} = $either->Sorted_keys if not exists $in->{ORDER};
		delete $in->{SLICEN};
	}

	my $Q = WooF::DB::Query->new("SELECT * FROM $table ")->parse_clause([%$in]);

	WooF::Object::Collection->new($class, $class->S->D->fetch_all($Q))->Set_State(DWHLINK);
}

=begin nd
Method: All_Fresh (%filter, @freshing, EXPAND => $expand)
	Получить Коллекцию самых свежих экземпляров.

	Свежесть определяется по полю 'ctime'.

	Группировка указывается явно. Но в будущем надо сделать так, чтобы при отсутствии явной группировки
	она происходила по первичному ключу.

	Аргументы метода делятся на три группы:
	- фильтр
	- наборы группировки
	- смежные члены класса

	В вызове группы могут следовать в произвольном порядке.

Parameters:
	%filter   - упакованный или распакованный (всё как обычно) хеш с условиями выборки для основного экземпляра
	@freshing - массив ссылок на массивы, каждый из которых состоит из списка полей группировки; аналог UNION
	$expand   - ссылка на массив, описывающий раскрываемые смежные классы

Returns:
	Коллекцию свежих экземпляров.
=cut
sub All_Fresh {
	my $either = shift;
	my $class = ref $either || $either;

	# $filter   - главный where
	# $expand   - дополнительные связанные экземлляры
	# $freshing - grouping sets
	my ($filter, $expand, $freshing) = _parse_args(@_);

	my %filter = @$filter;

	# имя базовой таблицы
	my $table = $class->Table;

	# поля, входящие в grouping sets + подготовленные для вставки в GROUP BY наборы строк
	my %grouping_sets_fields;
	my @grouping_sets;
	for my $set (@$freshing) {
		$grouping_sets_fields{$_} = undef for @$set;
		{
			local $" = ', ';
			push @grouping_sets, "(@$set)";
		}
	}
	my @grouping_sets_fields = keys %grouping_sets_fields;

	# условие в HAVING, выбирающее все записи, где есть нужные данные
	my $grouping_clause = join ' OR ', map "$_ IS NOT NULL", @grouping_sets_fields;

	# поля с квалификатором для вставки в PARTITION BY отсева дубликатов с одинаковым ctime
	my @qualified_maxctime_fields = map "ct.$_", @grouping_sets_fields;

	# строка условия для селф-джоин max_ctime с основной таблицей
	my $selfjoin_clause = join ' OR ', map "$table.$_ = ct.$_", @grouping_sets_fields;
	$selfjoin_clause = "($selfjoin_clause)" if @grouping_sets_fields > 1;

	my $Q = WooF::DB::Query->new->parse_clause($filter);

	# дополнительные связанные экземлляры в виде строки джоинов
	my $tree = {table => 'lasts', alias => undef, class => $class, extend => undef, parent => undef};  # дальнейший код изменит данный хеш
	my $ext_join = WooF::DB::Query->parse_expand(
		[],
		{
			class => $class,
			table => 'lasts',
			rc => '',
			init => 1,
			joined_tbls => undef,
		},
		$expand,
		$tree,
	);

	my $external_tables = $ext_join->{rc};

	my @selected_fields = map "lasts.$_ lasts\$$_", keys %{$class->Attribute};

	# в случае селф-джоинов, одинаковых таблиц может быть несколько, и им нужны алиасы
	while (my ($t, $desc) = each %{$ext_join->{joined_tbls}}) {
		my $class = $desc->{class};

		my @fields;
		for my $i (1 .. $desc->{n}) {
			my $table = $i > 1 ? $t . "_$i" : $t;
			@fields = map "$table.$_ $table\$$_", keys %{$class->Attribute};
			@selected_fields = (@selected_fields, @fields);
		}
	}

	my $ph = $Q->ph;
	my $q;
	{
		local $" = ', ';

		$q = qq{
			WITH
				max_ctime AS (
					SELECT
						@grouping_sets_fields,
						max(ctime) maxctime
					FROM
						$table
					WHERE
						@$ph
					GROUP BY
						grouping sets (@grouping_sets)
					HAVING
						$grouping_clause
				),
				lasts AS (
					SELECT
						$table.*,
						row_number() OVER (PARTITION BY @qualified_maxctime_fields ORDER BY id DESC) n
					FROM
							max_ctime ct
						JOIN
							$table
								ON @$ph AND $selfjoin_clause AND ct.maxctime = $table.ctime
				)
			SELECT
				@selected_fields
			FROM
					lasts $external_tables
			WHERE
				lasts.n = 1;
		};
	}

	my $rc = $class->S->D->fetch_all($q, $Q->val, $Q->val);

	WooF::Object::Collection->new($class)->Set_State(DWHLINK)->expand($tree, $rc);
}

=begin nd
Method: Attribute ( )
	Чисто виртуальный метод, должен быть перегружен потомком.

Returns:
	undef
	Возбуждает ошибку, так как не был перегружен потомком.
=cut
sub Attribute {
	my $self = shift;
	my $class = ref $self;

	return warn "OBJECT: 'Attribute()' method must be redefined in subclass $class AND not get up to WooF::Object class";
}

=begin nd
Method: AUTOLOAD ( )
	Генерация методов доступа к членам класса.
=cut
sub AUTOLOAD {
	my $self = shift;

	my $method = $self->_get_method_name($AUTOLOAD);

	return warn "OBJECT|ERR: Can't AUTOLOAD method $method on class $self without object." unless ref $self;
	return if $method eq 'DESTROY';
	return warn "OBJECT|ERR: Method AUTOLOAD: $AUTOLOAD in loop" if $Done{$AUTOLOAD};

	my $accessor =
			  $self->_accessible($method, READ) && $self->_accessible($method, WRITE) ? '_access_rw'
			: $self->_accessible($method, READ)                                       ? '_access_r'
			: $self->_accessible($method, WRITE)                                      ? '_access_w'
			:                                                                           '_access_no'
	;

	{	# Ограничим отмену strict, чтобы сработала следующая конструкция
		no strict 'refs';
		*{$AUTOLOAD} = $self->$accessor($AUTOLOAD);
	}

	$Done{$AUTOLOAD}++;
	$self->$method(@_);
}

=begin nd
Method: Count (@filter)
Получить количество элементов в выборке.
Данный метод может вызываться и как метод класса, и как метод экземпляра.

Сама выборка не производится, а лишь вычисляется count(*)

Parameters:
	@filter - условия выборки. Более подробно см. в описании к методу классе <WooF::DB::Query::parse_clause>

Returns:
	Целое число - количество подходящих под выборку экзепляров.
=cut
sub Count {
	my ($either, @filter) = @_;
	my $in = expose_hashes \@filter;

	my $table = $either->Table;
	my $Q = WooF::DB::Query->new("SELECT count(*) FROM $table ")->parse_clause([%$in]);

	$either->S->D->fetch($Q)->{count};
}

=begin nd
Method: Create ( )
	Создать новый экземпляр в базе данных.
=cut
sub Create {
	my $self = shift;

	return unless $self->S->D;
	my $table = $self->Table;

	my @attrs;
	my @values = map {
		if (
				not defined $self->{$_}
			or
				exists $self->Attribute->{$_}{type} and $self->Attribute->{$_}{type} eq 'cache'
		) {
			()
		} else {
			push @attrs, $_;
			($_ => $self->{$_});
		}
	} keys %{$self->Attribute};

	my @ph = split //, '?' x @attrs;

	my $q;
	{
		local $" = ', ';
		$q = "INSERT INTO $table (@attrs) VALUES (@ph)";
	}

	$self->S->D->exec($q, @values);
}

=begin nd
Method: DESTROY ()
	При утилизации экземпляра запишем его состояние в базу если надо.

	Если у экземпляра нет таблицы, значит он не является сущностью базы данных.
	Если экземпляр был удален, то сохранять его так же не нужно.
	Не нужно сохранять, если пользователь об этом явно попросил.
	Если экземпляр привязан к базе, но не был изменен, то сохранение не требуется.
=cut
sub DESTROY {
	my $self = shift;

	return unless $self->Table;
	return if     $self->{STATE} & REMOVED;
	return if     $self->{STATE} & NOSYNC;
	return if     $self->{STATE} & DWHLINK and not $self->{STATE} & MODIFIED;

	$self->Save;
}

=begin nd
Method: Expand ($expand)
	Расширить экземпляр экземплярами связанных классов.

	Описание связанных классов должно находиться в описаниях соответствующих атрибутов данного класса.

	Допускается расширение классов, связанных с данным классом связью многие-ко-многим. В этом случае описание
	атрибута выглядит так:
>	products    => {
>		type => 'cache',
>		extern => 'ALKO::Catalog::Product',
>		maps => {
>			class  => 'ALKO::Catalog::Product::Link',
>			master => 'id_category',
>			slave  => 'id_product',
>			set    => {face => 'face_effective'},
>		},
>	},

Parameters:
	$expand - строка с именем члена класса, подлежащего расширению или ссылка на массив таких строк.

Returns:
	$self - если ошибок не было
	undef - в случае ошибки
=cut
sub Expand {
	my ($self, $expand) = @_;
	my $class = ref $self;

	my @expand = ref $expand ? @$expand : $expand;  # связанные атрибуты, подлежащие расширению

	for my $expand (@expand) {
		my $attr = $class->Attribute;
		my $expand_attr = $attr->{$expand};

		# Существуют требования к расширяемому атрибуту
		return warn "Can't Get() extended data for class=$class"
			unless
					$self->isa('WooF::Object::Simple')
				and
					defined $expand_attr
				and
					exists $expand_attr->{type} and $expand_attr->{type} eq 'cache'
				and
					exists $expand_attr->{extern}
				and
					exists $expand_attr->{maps};

		# собираем поля из дополнительной таблицы связанных экземпляров
		my $slave_class = $expand_attr->{extern};
		my $slave_table = $slave_class->Table;
		my $slave_attr = $slave_class->Attribute;
		my @selected_fields;
		while (my ($at, $des) = each %$slave_attr) {
			next if defined $des and ref $des eq 'HASH' and exists $des->{type} and $des->{type} eq 'cache';

			push @selected_fields, "$slave_table.$at $slave_table\$$at";
		}

		# собираем поля из таблицы-связки
		my $maps = $expand_attr->{maps};
		my $link_class = $maps->{class};
		my $link_table = $link_class->Table;
		my $link_attr = $link_class->Attribute;
		while (my ($at, $des) = each %$link_attr) {
			next if defined $des and exists $des->{type} and $des->{type} eq 'cache';

			push @selected_fields, "$link_table.$at $link_table\$$at";
		}

		my $q;
		{
			local $" = ', ';
			$q = qq{
				SELECT @selected_fields
				FROM $slave_table JOIN $link_table ON $slave_table.id = $link_table.$maps->{slave}
				WHERE $link_table.$maps->{master} = $self->{id}
			};
		}
		my $rows = $class->S->D->fetch_all($q);

		# заполняем хеши экземпляров
		my @slave_src;
		for my $row (@$rows) {
			my (%slave_item, %link_item);
			while (my ($attr, $v) = each %$row) {
				my ($table, $field) = $attr =~ /^(.+)\$(.*)$/;

				if ($table eq $slave_table) {
					$slave_item{$field} = $v;
				} else {
					$link_item{$field} = $v;
				}
			}

			# если указан set, заполняем экземпляры коллекции соответствующим значением из таблицы связки
			if (defined $maps->{set}) {
				while (my ($src, $dst) = each %{$maps->{set}}) {
					$slave_item{$dst} = $link_item{$src} if defined $link_item{$src};
				}
			}

			push @slave_src, \%slave_item;
		}
		$self->{extend}{$expand} = WooF::Object::Collection->new($slave_class, \@slave_src)->Set_State(DWHLINK);
	}

	$self;
}

=begin nd
Method: Generate_Key ( )
	Сгенерировать экземпляру первичный ключ.

	Чисто виртальный метод, должен быть перегружен потомком.

	В общем случае, метод вызывается только тогда, когда экземпляр не привязан к базе
	и у него не определен первичиный ключ, при этом первичный ключ нуждается в генерировании.
	Такой сценарий маловероятен. Например, с ключом, состоящим из единственного атрибута,
	такой атрибут, как правило, имеет дефолтное значение в базе.

Returns:
	undef
	Возбуждает ошибку, так как не был перегружен потомком.

	В потомках необходимо возвращать true в случае удачного генерирования,
	и undef, если не получилось.
=cut
sub Generate_key {
	my $self = shift;
	my $class = ref $self;

	return warn "OBJECT|ERR: Generate_Key method must be redefined in subclass $class";
}

=begin nd
Method: Get (@filter, EXPAND => $expand)
	Получить экземпляр класса, удовлетворяющего условиям.

	Данный метод может вызываться и как метод класса, и как метод экземпляра.

	Хотя бы одно условие выборки должно присутствовать, иначе метод потерпит неудачу.

	Если в аргументах присутствует $expand, он должен содержать ссылку на массив имен (или одно имя_атрибута
	в виде строки) члена класса, подлежащего "расширению".
	Описание такого члена класса содержит данные для получения коллекции экземпляров другого класса,
	связанного с текущим отношением многие-ко-многим.

Parameters:
	@filter - условия выборки. Более подробно см. в описании к методу parse_clause в классе WooF::DB::Query.
	$expand - строка с именем члена класса, подлежащего расширению или ссылка на массив таких строк.

Returns:
	Экземпляр класса в случае наличия единственного экземпляра.
	undef в противном случае - если экземпляров, удовлетворяющих условию больше одного, нет ни одного,
	или не задано условие выборки.
	Если указано расширение, то коллекция будет помещена в хеш 'extend'.
=cut
sub Get {
	my $either = shift;
	my $class = ref $either || $either;

	my ($filter, $expand) = _parse_args(@_);

	return warn 'OBJECT|ERR: filter not defined' unless @$filter;

	# получаем основной экземпляр
	my $table = $class->Table;
	my $Q = WooF::DB::Query->new("SELECT * FROM $table ")->parse_clause($filter);

	my ($rows) = $class->S->D->fetch($Q);

	my $row = shift @$rows or return warn "| NOTICE : Can't Get exemplar for $class";
	return warn "| NOTICE : Multiple rows for $class exemplar" if @$rows;

	my $self = $class->new($row);
	$self->{STATE} |= DWHLINK;

	# получить связанные коллекции многие-ко-многим
	$self->Expand($expand) if defined $expand;

	$self;
}

=begin nd
Method: _get_method_name ($full_name)
	Выделить имя метода, отбросив имя пакета.

Parameters:
	$full_name - полное имя метода, включающее имя пакета

Returns:
	Имя метода без лидирующей части.
=cut
sub _get_method_name {
	my ($self, $full_name) = @_;
	$full_name =~ /.*::(\w+)/o;

	$1;
}

=begin nd
Method: Has ($extended)
	Расширен ли у экземпляра указанный атрибут.

Parameters:
	$extended - имя атрибута

Returns:
	Экземпляр или коллекцию, привязанную к атрибуту - если таковые имеются
	undef - в противном случае
=cut
sub Has {
	my ($self, $attr) = @_;

	exists $self->{extend} and exists $self->{extend}{$attr} ? $self->{extend}{$attr} : undef;
}

=begin nd
Method: Is_key_defined ( )
	Определен ли ключ у экземпляра.
	Генерируется одноименный метод в вызывающем классе,
	после чего он же и вызывается повторно.

Returns:
	true  - если ключ полностью определен
	false - в противном случае
=cut
sub Is_key_defined {
	my $self = shift;
	my $class = ref $self;

	my $keys = $self->Key_attrs or return warn "OBJECT|ERR: Can't call Is_key_defined() since no keys exist for $class";

	my $method = sub {
		my $self = shift;

		for (keys %$keys) {
			return unless defined $self->{$_};
		}

		1;
	};
	{
		no strict 'refs';
		*{$class . '::Is_key_defined'} = $method;
	}

	$self->Is_key_defined;
}

=begin nd
Method: Key_attrs ( )
	Получить ключи класса.

	В вызывающем классе генерируется метод доступа к методу экземпляра класса Key, который хранится в пакетной переменной.
	Если экземпляра нет, то он создается, и в своем конструкторе сразу вычисляет все нужные ему данные и запоминает результаты в своих членах класса.
	Так что вся тяжелая работа происходит только один раз, а в дальнейшем данный метод через пакетную переменную-экземпляр отдает уже готовые данные.

Returns:
	Ссылку на хеш - ключами служат имена атрибутов-ключей класса,
	а значениями описания этих ключей, которые могут быть просто undef.

	undef - в случае ошибки.
=cut
sub Key_attrs {
	my $self = shift;
	my $class = ref $self;

	{
		no strict 'refs';

		my $keys = \${$class . '::KEYS'};
		$$keys ||= WooF::Object::Key->new($class);

		*{$class . '::Key_attrs'} = sub { $$keys->attr_desc };
	}

	$self->Key_attrs;
}

=begin nd
Method: Modified ($remove)
	Поменять экземпляру флаг 'модифицированный'.

	Если флага нет, или он не равен нулю, то флаг устанавливается.
	В противном случае (если ноль), сбрасывается.

Parameters:
	$remove - если 0, то флаг сбрасывается

Returns:
	$self
=cut
sub Modified {
	my ($self, $remove) = @_;

	if (defined $remove and $remove == 0) {
		$self->Remove_State(MODIFIED);
	} else {
		$self->Set_State(MODIFIED);
	}

	$self;
}

=begin nd
Method: Nosync ()
	Отменить синхронизацю экземпляра при его утилизации.

Returns:
	Сам экземпляр $self. Так что, можно писать:
> $Obj = My::Class->new()->Nosync;
=cut
sub Nosync {
	my $self = shift;

	$self->{STATE} |= NOSYNC;

	$self;
}

=begin nd
Function: _parse_args (%filter, $expand, @sets)
	Распарсить аргументы достающих экземпляры методов на основные входные группы.

	Функция, не метод.

	Ссылка на массив после 'EXPAND' это $expand,
	остальные ссылки на массив это @sets,
	все оставшееся это %filter.

Parameters:
	Основными входными группами являются:
	условия выборки -хеш, упакованный в массив
	наборы          - ссылки на массивы
	$expand         - пара, в которой ключом является служебное слово 'EXPAND', а значением ссылка на массив

Returns:
	(\%filter, \$expand, \@sets)
=cut
sub _parse_args {
	my @filter;    # главный where
	my $expand;    # дополнительные связанные экземлляры
	my @sets;  # grouping sets

	my $expand_wait;
	for my $el (@_) {
		if ($expand_wait) {
			$expand = $el;
			undef $expand_wait;
			next;
		}

		my $ref = ref $el;

		if ($ref and $ref eq 'ARRAY') {
# 			if ($expand_wait) {
# 				$expand = $el;
# 				undef $expand_wait;
# 				next;
# 			}
			push @sets, $el;
		} else {
			if ($el eq 'EXPAND') {
				$expand_wait = 1;
				next;
			}
			push @filter, $el;
		}
	}

	(\@filter, $expand, \@sets);
}

=begin
Method: Prepare_key ( )
	 Готовит ключ для вставки.

	 Чисто виртуальный метод, должен быть перегружен потомком.

Returns:
	true
=cut
sub Prepare_key {
	my $self = shift;
	my $class = ref $self;

	return warn "OBJECT: Prepare_key method must be redefined in subclass $class";
}

=begin nd
Method: Refresh ( )
	Обновить атрибуты экземпляра в базе.
=cut
sub Refresh {
	my $self = shift;

	my $table = $self->Table;

	my (@fields, @keys, @key_param);
	my @param = map {
		if (exists $self->Key_attrs->{$_}) {
			push @keys, $_;
			push @key_param, $_ => $self->{$_};
			();
		} elsif (defined $self->Attribute->{$_} and exists $self->Attribute->{$_}{type} and $self->Attribute->{$_}{type} eq 'cache') {
			();
		} else {
			push @fields, $_;
			($_ => $self->{$_});
		}
	} keys %{$self->Attribute};

	my @ph = split '', '?' x @fields;
	@param = (@param, @key_param);
	@keys = map "$_ = ?", @keys;

	my $Q;
	{
		local $" = ', ';
		$Q = WooF::DB::Query->new("UPDATE $table SET (@fields) = (@ph)");
	}
	{
		local $" = ' AND ';
		$Q->where("@keys");
	}

	$self->S->D->exec($Q->print, @param);
}

=begin nd
Method: Remove ()
	Удаление экземпляра.

	Кортеж сразу удаляется из базы, экземпляру в коде выставляется флаг 'REMOVED'.

Returns:
	undef
=cut
sub Remove {
	my $self = shift;
	my $class = ref $self;

	my $table = $self->Table;
	return warn "OBJECT|ERR: Can't remove object with no Table specified in class $class" unless $table;

	my @ph;
	my @param = map {
		push @ph, "$_ = ?";
		($_ => $self->{$_});
	} keys %{$self->Key_attrs};

	my $Q = WooF::DB::Query->new("DELETE FROM $table");
	$Q->where(join ' AND ', @ph);

	$self->S->D->exec($Q, @param);

	$self->{STATE} |= REMOVED;
}

=begin nd
Method: Remove_State ($flags)
	Сбросить у специального члена класса STATE флаги $flags.

Parameters:
	$flags - набор флагов в виде битовой маски, подлежащие снятию.
Returns:
	$self
=cut
sub Remove_State {
	my ($self, $flags) = @_;

	$self->{STATE} &= ~$flags;

	$self;
}

=begin nd
Method: Save
	Принудительное (форсированное) сохранение экземпляра в базе данных.

	Флаг NO_SYNC отменяет режим автоматического сохранения, однако он не может препятствовать принудительному сохранению.
	Экземпляру выставляется флаг привязки к базе, и снимается флаг изменений по отношению к базе.

	Предполагается, что если экземпляр привязан к базе, то первичный ключ у него определен.

Returns:
	Экземпляр - если сохранение прошло удачно.
	undef в противном случае.
=cut
sub Save {
	my $self = shift;
	my $class = ref $self;

	return warn "OBJECT|ERR: Can't Save object with no TABLE specified for class $class" unless $self->Table;

	if ($self->{STATE} & DWHLINK) {        # экземпляр присутствует в базе данных
		return $self unless $self->{STATE} & MODIFIED;      # экземпляр не нуждается в апдейте, т.к. соответствует состояню в базе
		$self->Refresh;
	} else {                               # экземпляра еще нет в базе
		$self->Is_key_defined or $self->Prepare_key or return warn "OBJECT|ERR: Can't Generate Primary key for class $class";
		$self->Create;
	}

	$self->{STATE} |= DWHLINK;
	$self->{STATE} &= ~MODIFIED;

	$self;
}

=begin nd
Method: Set_State ($flags)
	Поднять у специального члена класса STATE флаги $flags.

	Обычно делать этого руками не требуется, и данный метод используется только для удобства в <WooF::Object>.
	Но могут быть случаи на малосвязанном коде, когда он в принципе будет удобен.

Parameters:
	$flags - набор флагов в виде битовой маски, подлежащие установке.

Returns:
	$self
=cut
sub Set_State {
	my ($self, $flags) = @_;

	$self->{STATE} |= $flags;

	$self;
}
=begin nd
Method: Sorted_keys
	Получить ссылку на массив имен ключевых полей упорядоченных в соответствии с тем, как они индексируются в БД.

	В вызывающем классе генерируется метод доступа к методу экземпляра класса Key, который хранится в пакетной переменной.
	Если экземпляра нет, то он создается, и в своем конструкторе сразу вычисляет все нужные ему данные и запоминает результаты в своих членах класса.
	Так что вся тяжелая работа происходит только один раз, а в дальнейшем данный метод через пакетную переменную-экземпляр отдает уже готовые данные.

Returns:
	Ссылку на массив.
=cut
sub Sorted_keys {
	my $either = shift;
	my $class = ref $either || $either;
	{
		no strict 'refs';

		my $keys = \${$class . '::KEYS'};
		$$keys ||= WooF::Object::Key->new($class);

		*{$class . '::Sorted_keys'} = sub { $$keys->sorted_list };
	}

	$either->Sorted_keys;
}

=begin nd
Method: Sync ()
	Запросить синхронизацю экземпляра при его утилизации.
	Сбрасывается флаг NOSYNC.

Returns:
	Сам экземпляр $self. Так что, можно писать:
> $Obj = My::Class->new()->Sync;
=cut
sub Sync {
	my $self = shift;

	$self->{STATE} &= DOSYNC;

	$self;
}


=begin nd
Method: Table ( )
	Если класс не подразумевает сохранения в БД, то метод Table должен вернуть false.
=cut
sub Table { undef }

=begin nd
Method: TO_JSON ($data)
	Декодировать блесснутые данные для JSON.

	Поскольку у нас все экземпляры реализованы хешами, то и отдаем просто разблеснутый хеш.

	Из полученного хеша удаляется контейнер флагов 'STATE'.

	Метод вызывается автоматически модулем JSON для каждой блесснутой ссылки.

Parameters:
	$data - блеснутый хеш

Returns:
	разблеснутый хеш
=cut
sub TO_JSON {
	my $data = shift;

	my $json =  {%$data};
	delete $json->{STATE};

	$json;
}

1;
