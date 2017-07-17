package WooF::Object::Collection;
use base qw/ WooF::Object /;

=begin nd
Class: WooF::Object::Collection
	Контейнер экземпляров одного класса.
	
	Имя класса элементов (строка) хранится в члене класса 'class'.
	
	Сами элементы (экземпляры) находятся в @{$self->{elements}}.

	Флаги коллекции ('state') соответствуют флагам экземпляров.
	Поэтому флаги коллекции нужно изменять с помощью методов <Set_State> и <Remove_State>.

	Коллекция работает исходя из предположения, что все ее элементы однородны. 
	То есть, обладают одинаковыми значениями служебных флагов и одинаковым состоянием ключевых атрибутов. 
	В будущем, возможно, у Коллекции появится флаг "разношерстности элементов", 
	и тогда она сможет работать с элементами, находящимися в отличных друг от друга состояниях.
	
	В члене классса 'hash' хранятся хеши быстрого доступа к элементам коллекции.
	Такие хеши кешируются, их может быть несколько, и они находятся в $self->{hash} по тому имени члена класса элемента, по которому отхешированы.
	Например:
	> $collection->Hash('id_attr'); # создаст в коллекции:
	> $self->{hash}{id_attr} = {1 => {id_attr=>1,...}, 5 => {id=>5,...}, ...}; # только хеши являются экземплярами.
	
	Член класса 'simple' defined, если элементы коллекции являются потомками <WooF::Object::Simple> и является ссылкой на массив ид'шников.
	
	Пользователям WooF нет необходимости создавать Коллекцию непосредственно. Им следует использовать метод <WooF::Object::All>. 
=cut

use strict;
use warnings;
no warnings 'experimental';

use 5.014;

use WooF::Error;
use WooF::Util;
use WooF::DB::Query;
use WooF::Object::Constants;

=begin nd
Variable: $AUTOLOAD
	Имя всплывшего метода. Если такого метода нет в данном классе (классе коллекций),
	то его нужно вызвать для всех его членов.

	см. <AUTOLOAD>
=cut
use vars qw/ $AUTOLOAD /;

=begin nd
Constructor: new ($bless, $obj)
	Создает коллекцию указанного класса.
	
	Если класс элементов коллекции наследует <WooF::Object::Simple>, то id элементов
	запоминаются в массиве simple.

	Член класса 'state' имеет такую же семантику, что и 'STATE' в <WooF::Object>.
	Изначально state устанавливается в <WooF::Constants::OBJINIT>.
	Все добавляемые елементы коллекции будут инициированы этим с таким state.
Parameters:
	$bless - класс, которому принадлежат все элементы коллекции
	$obj   - ссылка на массив хешей, в котором лежат данные экземпляров

Returns:
	Коллекцию.
=cut
sub new {
	my ($class, $bless, $obj) = @_;
	$obj = [] unless defined $obj;

	my $is_simple = $bless->isa('WooF::Object::Simple');

	my (@exemplar, @id);
	for (@$obj) {
		push @exemplar, $bless->new($_);
		push @id, $_->{id} if $is_simple;
	}

	my $self = bless {
		class    => $bless,
		elements => \@exemplar,
		state    => OBJINIT,
		hash     => undef,  # кэш хранения хеша по ключу; например: ($self->{hash}{id})
	}, $class;
	
	$self->{simple} = [] if $is_simple;
	$self->{simple} = \@id if @id;

	$self;
}

=begin nd
Method: AUTOLOAD ($value)
	Вызов методов экземпляров, входящих в коллекцию.
	
	Если метод отсутствует для коллекции, то он применяется к каждому ее элементу.
	В итоге конкретному полю каждого элемента устанавливается переданное методу значение.
	Глобальный сеттер.
	
Parameters:
	$value - устанавливаемое значение атрибута; обязательный параметр

Returns:
	$self
=cut
sub AUTOLOAD {
	my ($self, $value) = @_;

	return unless $value;

	my $method = $self->SUPER::_get_method_name($AUTOLOAD);

	$_->$method($value) for @{$self->{elements}};

	$self->{SHAREVAL}{$method} = $value;

	$self;
}

=begin nd
Method: Clone (%map)
	Клонирование коллекции целиком.

	Копирует исходную коллекцию, от которой осуществляется вызов метода, в новую 
	возвращаемую коллекцию с не определенными (если преобразование не указано явно) ключевыми атрибутами.

Parameters:
	%map - позволяет для каждого атрибута новой коллекции задать атрибут-источник из исходной коллекции;
	необязательный параметр.
	Список аргументов может включать в себя хеш с именем 'CALC', реализующий порядок отображения, 
	обратный основному мапингу, а именно - цель => значение, 
	и используется для определения подпрогарммы расчета значения нового поля, 
	или константного выражения, которое будет присвоено одноименным полям всех элементов коллекции
	Например:
(start code)
	$col->Clone(id => 'id_old', id_old => 'id'); # поменяет id и id_old местами
	# поменяет surname на name и увеличит id_request на 1
	$col->Clone(name => 'surname', CALC => { id_request => sub { +shift->id_request + 1; } });
	$col->Clone(CALC => { name =>  'Вася'}); # поменяет имя на Вася для всех элементов коллекции
(end)

Returns: 
	Новую, получившуюся в результате клонирования, коллекцию.
=cut
sub Clone {
	my ($self, %map) = @_;
	my $calculate = $map{CALC};
	delete $map{CALC};
	%map = reverse %map;

	my $clone = WooF::Object::Collection->new($self->{class});

	for my $orig  (@{$self->{elements}}) {
		my %item = map
			  exists $map{$_}         ? ($_ => $orig->{$map{$_}})
			: exists $orig->Key_attrs->{$_} ? ()
			:                           ($_ => $orig->{$_})
		, keys %{$orig->Attribute};

		while (my ($attr, $expr) = each %$calculate) {
			$item{$attr} = ref $expr eq 'CODE' ? $expr->($orig) : $expr;
		}

		$clone->Push(\%item);
	}

	$clone;
}

=begin nd
Method: DESTROY ( )
	Особенное сохранение экземпляров коллекции при ее утилизации.

	Если класс коллекции наследует <WooF::Object::Simple>
	и был применен глобальный сеттер <WooF::Object::Collection::AUTOLOAD>,
	UPDATE всех экземпляров в базе будет произведен одним запросом.

	Если класс коллекции наследует <WooF::Object::Simple>
	и коллекция не привязна к БД, 
	INSERT всех экземпляров в базе будет произведен одним запросом.
=cut
sub DESTROY {
	my $self = shift;

	return if     $self->{state} & NOSYNC;
	return if     $self->{state} & DWHLINK and not $self->{state} & MODIFIED;
	return unless exists $self->{simple} and @{$self->{simple}};
	return unless @{$self->{elements}};

	$self->Save;
}

=begin nd
Method: Expand ($attr)
	Расширить указанный атрибут во всех элементах коллекции.
	
	В отличие от <expand> и <_expand> предназначен для вызова с уровня пользовательского кода.
	
	Метод может расширить только один атрибут из класса, связанного с классом коллекции связью
	один-ко-многим со стороны "многие".
	Класс коллекции должен быть наследником <WooF::Object::Simple>.
	
Parameters:
	$attr - имя атрубита из связанного класса.
	
	Определение атрибута в классе коллекции должно указывать на то, что атрибут является кеширующим,
	содержать имя свзязанного класса, и имена связующих полей в основном и связанном классе.
	
Returns:
	$self - если операция прошла без ошибок
	undef - в противном случае
=cut
sub Expand {
	my ($self, $attr) = @_;
	my $class = ref $self;
	
	return warn "OBJECT: Collection can't Expand() non-Simple class $self->{class}" unless $self->{class}->isa('WooF::Object::Simple');
	
	return $self unless @{$self->{elements}};
	
	my $master_attr = $self->{class}->Attribute->{$attr};
	
	my $slave_class = $master_attr->{extern};
	my $slave_field = $master_attr->{maps}{slave};
	
	# в случае потомка Sequence индекс будет в возрастающем порядке
	my $slave = $slave_class->All($master_attr->{maps}{slave} => $self->{simple}, SORT => 'DEFAULT');

	$_->$attr($class->new($slave_class)) for @{$self->{elements}};

	for ($slave->List) {
		my $master = $self->First_Item(id => $_->$slave_field) or next; # по идее экземпляр быть обязан, но вдруг...
		
		$master->$attr($class->new($slave_class)) unless $master->$attr;
		$master->$attr->Push($_);
	}
	
	$self;
}

=begin nd
Method: expand ($tree, $src)
	На основании готовой выборки из базы данных получить Коллекцию.
	
	Описание структуры элементов коллекции, включающей описание вложенных экземпляров
	и передаваемой первым аргументом, имеет специальный формат, который сложно создать
	в коде пользовательского уровня:
(start code)	
$tree = $VAR1 = {
	parent => undef,
	class => 'NABI::Chat',
	table => 'lasts',
	alias => undef,
	extend => {
		dstcustomer => {
			name => 'dstcustomer',
			parent => $VAR1,
			class => 'NABI::User::Customer',
			table => 'customer',
			alias => '',
			extend => {
				avatar => {
					name => 'avatar',
					parent => $VAR1->{'extend'}{'dstcustomer'},
					class => 'NABI::File',
					table => 'file',
					alias => '',
					extend => undef,
				}
			},
		},
		dstdriver => {
			name => 'dstdriver',
			parent => $VAR1,
			class => 'NABI::User::Driver',
			table => 'driver',
			alias => '',
			extend => {
				avatar => {
					table => 'file',
					class => 'NABI::File',
					name => 'avatar',
					alias => 'file_2',
					extend => undef,
					parent => $VAR1->{'extend'}{'dstdriver'},
				},
			},
		},
	},
};
(end)
	Поэтому данный метод должен использоваться исключительно
	из объектного слоя (см. <WooF::Object::All_Fresh (%filter, @freshing, EXPAND => $expand)>).
	
	См. также: <_expand ($node, $tuple, $parent)>

Parameters:
	$tree - дерево разбора, описано выше
	$src  - массив хешей выборки из базы, источник данных для элементов коллекции
	
Returns:
	$self
=cut
sub expand {
	my ($self, $tree, $src) = @_;
	
	$self->_expand($tree, $_, undef) for @$src;
	
	$self;
}

=begin nd
Method: _expand ($node, $tuple, $parent)
	На основании конкретной записи из базы данных заполнить текущую ноду экземпляра.
	
	Служебный метод, производящий основную работу для <expand ($tree, $src)>
	
	Вызывается рекурсивно.
	
Parameters:
	$node   - текущая нода дерева, определяющая правила разбора
	$tuple  - текущая запись из базы данных со значениями для заполнения полей экземпляра
	$parent - родитель текущей ноды; если undef, то родителем является сама коллекция,
	и полностью сформированный элемент будет помещен в нее
=cut
sub _expand {
	my ($self, $node, $tuple, $parent) = @_;

	my $class = $node->{class};

	my $item;
	for (keys %{$class->Attribute}) {
		my $table = $node->{alias} || $node->{table};
		my $field = "$table\$$_";
		$item->{$_} = $tuple->{$field};
	}
	my $obj = $class->new($item)->Set_State($self->{state});
	return unless $obj->Is_key_defined;

	if (defined $parent) {
		$parent->{expand}{$node->{name}} = $obj;
	} else {
		$self->Push($obj);
	}

	if (defined $node->{extend}) {
		for (keys %{$node->{extend}}) {
			my $next = $node->{extend}{$_};
			$self->_expand($next, $tuple, $obj);
		}
	}
}

=begin nd
Method: Find (%filter)
	Получить индексы элементов, удовлетворяющих условиям поиска

Parameters:
	%filter - хеш ключи в котором - члены класса, а значения - значения, 
	которые должны иметь эти члены в искомых объектах коллекции

Returns:
	ссылка на массив индексов найденных экземпляров или пустой список
=cut
sub Find {
	my ($self, %filter) = @_;

	my @found;

	ITEM:
	while (my ($i, $item) = each @{$self->{elements}}) {
		exists $item->{$_} and $item->{$_} eq $filter{$_} or next ITEM for keys %filter;
		push @found, $i;
	}

	\@found;
}

=begin nd
Method: First_Item (@filter)
	Получить первый встретившийся в коллекции экземпляр, удовлетворяющий условию в @filter.
	
Parameters:
	@filter - упакованный в массив хеш условий.
	Например:
	> my $obj = $collection->Find(id => 25, color => 'red', {smoke = 'yes'});
	
	Хеши в @filter будут распакованы.
	
Returns:
	экземпляр класса коллекции - если экземпляр, подходящий под условя, найденн
	undef                      - если в коллекции не оказалось подходящего экземпляра
=cut
sub First_Item {
	my ($self, @filter) = @_;
	my $filter = expose_hashes \@filter;
	
	my $i = shift @{$self->Find(%$filter)};

	# $i может иметь легальное значение 0
	defined $i or return undef;
	
	$self->Get($i);
}

=begin nd
Method: Get ($i)
	Получить i-й элемент коллекции

Parameters:
	$i - номер элемента коллекции

Returns:
	Элемент коллекции
=cut
sub Get {
	my ($self, $i) = @_;

	$self->{elements}[$i];
}

=begin nd
Method: Hash ($attr)
	Вывести коллекцию в виде хеша.
	
	Часто бывает нужно иметь экземпляры внутри хеша по нужному ключу.
	
	Метод конструирует хеш возврата и сохраняет его в $self->{hash}{$attr}. При следующем вызове сначала проверяется этот кеш.

Parameters:
	$attr - имя атрибута, определяющего ключ хеша.

Returns:
	В общем случае хеш массивов, где ключом хеша является значение поля $attr, а значениями хеша массивы всех элементов,
	сгруппированных по ключу:
	> {
	>     one => [{$attr=>'one', <etc attributes>}, {$attr=>'one', <etc>}, ...],
	>     ...,
	> }
	
	Есть один вырожденный случай, когда элементы классов являются потомками класса <WooF::Object::Simple> и не указан аргумент - атрибут группировки $attr.
	В этом случае возвращается не хеш массивов, а хеш элементов по ключу 'id', так как предпологается, что идентификатор уникален.
	Но если 'id' указан явно, метод работает в обычном режиме, возвращая хеш массивов.
=cut
sub Hash {
	my ($self, $attr) = @_;
	
	my $is_flat;  # Выводить ли элементы без заключения в массив
	unless ($attr) {
		return warn "OBJECT: Can't build 'hash-of-exemplar' for Collection of non-simple class: $self->{class}" unless exists $self->{simple};
		$attr = 'id';
		$is_flat = 1;
	}
	
	return $self->{hash}{$attr} if exists $self->{hash}{$attr};
	
	my %hash;
	if ($is_flat) {
		%hash = map +($_->{id} => $_), @{$self->{elements}};
	} else {
		push @{$hash{$_->{$attr}}}, $_ for @{$self->{elements}};
	}

	$self->{hash}{$attr} = \%hash;
}

=begin nd
Method: _Insert ( )
	Если класс коллекции наследует <WooF::Object::Simple>
	INSERT всех экземпляров в базе будет произведен одним запросом.
	
	Перед вставкой будут сгенерированы первичные ключи в случае их отсутствия.

	DB:: exec нуждается в оптимизации. 
	Сейчас в exec значения биндятся построчно через bind_param.
	Нужно добавить возможность делать тоже самое 
	через bind_array при большом количестве строк.

Returns:
	$self
=cut
sub _Insert {
	my $self = shift;
	my $class = ref $self;

	unless ($self->{elements}[0]->Is_key_defined) {
		my $keys = $self->{class}->Get_keys(scalar @{$self->{elements}}) or return warn "OBJECT: Can't insert collection of $class without keys";
		while (my ($ix, $primary) = each @$keys) {
			my ($k, $v);
			$self->{elements}[$ix]{$k} = $v while ($k, $v) = each %$primary;
			$self->{simple}[$ix] = $primary->{id} if exists $self->{simple};
		}
	}

	my (@fields, @param);
	for my $attr (keys %{$self->{class}->Attribute}) {
		next if exists $self->{class}->Attribute->{$attr}{type} and $self->{class}->Attribute->{$attr}{type} eq 'cache';
		my @val;
		push @val, $_->{$attr} for @{$self->{elements}};
		push @fields, $attr;
		push @param, $attr => \@val;
	}
	my @ph = split '', '?' x @fields;

	my $table = $self->{class}->Table;
	my $q;
	{
		local $" = ', ';
		$q = qq{INSERT INTO $table (@fields) VALUES (@ph)};
	}
	$self->S->D->exec($q, @param);
	
	$self->Set_State(DWHLINK)->Remove_State(MODIFIED);
}

=begin nd
Method: List ($id)
	Получить список элементов коллекции.
	Данный метод в случае необходимости выполняет для коллекции явное разыменовывание.

Parameters:
	id - необязательный параметр

Returns:
	Ссылку на массив элементов в скалярном контексте,
	и непосредственно массив в случае вызова из спискового контекста,
	что удобно в случае for, что в коде встречается постоянно.

	Если элементы коллекции - экземпляры класса Simple и передан параметр 'id' вернется массив(ссылка на массив) ключей.

	Первый пример:
		my $obj = NABI::Chat->All_Fresh(...);
		for my $message ($obj->List) {...}
	Здесь переменная $obj содержит ссылку на коллекцию сообщений, полученную с помощью метода All_Fresh.
	Далее, цикл for должен пройтись по всем элементам этой коллекции.
	Если бы не было методв List, то пришлось бы делать явное разыменование:
		for my $message (@$obj) {...}
	Здесь же метод List определяет, что находится в списковом контексте, и сам выполняет разыменование.

	Второй пример:
		my $response = NABI::Order::Response->All(...)->List;
	Метод List определил, что находится в скалярном контексте. В этом случае он возвращает ссылку на массив из элементов коллекции.

	Третий пример:
	Использование с методом MAP в списковом контексте:
		map { if (...) { ... } else { ... } } NABI::User::Customer->All->List;
	Блочный формат MAP подразумевает, что вторым аргументом будет массив экземпляров класса Customer.
	Метод List определяет, что находится в списковом контексте, и сам выполняет требуемое разыменовывание.

	Ещё один пример, когда List выполняет разыменовывание:
	> ... = map $_->extra_info($I->{start}), NABI::User::Driver->All->List;
=cut
sub List {
	my ($self, $id) = @_;

	return wantarray ? @{$self->{simple}} : $self->{simple} if $self->{class}->isa('WooF::Object::Simple') and $id and $id eq 'id';
	
	wantarray ? @{$self->{elements}} : $self->{elements};
}

=begin nd
Method: Push ($src)
	Добавить элемент(ы) в конец коллекции.
	
	Элемент добавляется с установленными флагами, хранящимися в state коллекции.

Parameters:
	$src - добавляемый элемент коллекции, который может быть либо экземлпяром класса коллекции,
	либо хешем атрибутов, готовых к передаче конструктору класса коллекции.
	
	В случае множества добавляемых экземлпяров или хешей, в $src можно передать ссылку на их массив.
	
Returns:
	$self
=cut
sub Push {
	my ($self, @src) = @_;
	my @add = map ref eq 'ARRAY' ? @$_ : $_, @src;

	for (@add) {
		my $item = ref eq $self->{class} ? $_ : $self->{class}->new($_);
		$item->Set_State($self->{state});
		
		push @{$self->{elements}}, $item;
		push @{$self->{simple}}, $item->{id} if exists $self->{simple};
	}
	
	$self;
}

=begin nd
Method: Remove_State ($flags)
	Сбросить коллекции флаги.

	Указанные флаги сбрасываются и самой коллекции, и каждому ее элементу.

Parameters:
	$flags - сбрасываемые флаги <WooF::Object::Constants>

Returns:
	$self
=cut
sub Remove_State {
	my ($self, $flags) = @_;

	$self->{state} &= ~$flags;
	
	$_->Remove_State($flags) for @{$self->{elements}};
	
	$self;
}

=begin nd
Method: replace ($from, $to)
	Заменить элемент коллекции.
	
	Если коллекция содержит потомки <WooF::Object::Simple>, будет соответствующий образом изменен и
	масси id'шников. Необходимо учесть, что если ид'шники повторяются, то в simple будут заменены все,
	несмотря на то, что в элементах произойден лишь единственная замена хеша по ссылке. Таким образом,
	не рекомендуется вызывать даннй метод в случае дубликатов.
	
Parameters:
	$from - ссылка на заменяемый элемент, сам экземпляр
	$to   - новый экземпляр
	
Returns:
	Коллекцию.
=cut
sub replace {
	my ($self, $from, $to) = @_;
	
	my $stale_id = $from->{id} if $from->isa('WooF::Object::Simple');
	
	%$from = %$to;
	
	if (exists $self->{simple}) {
		my ($i, $val);
		$val == $stale_id and $self->{simple}[$i] = $to->{id} while ($i, $val) = each @{$self->{simple}};
	}
	
	$self;
}

=begin nd
Method: Save ( )
	Сохранить все элементы коллекции. Флаг NOSYNC игнорируется.

	Если класс коллекции наследует <WooF::Object::Simple>
	и был применен глобальный сеттер <WooF::Object::Collection::AUTOLOAD>,
	UPDATE всех экземпляров в базе будет произведен одним запросом.
	
	Если коллекция не привязна к БД, 
	INSERT всех экземпляров в базе будет произведен одним запросом.

	Вызов Save для не симпл-коллекции, привязанной к базе, приведет к возврату ошибки, т.к. _Update умеет работать только с <WooF::Object::Simple>.

	_Update не умеет сохранять изменения, если не был применен глобальный сеттер <WooF::Object::Collection::AUTOLOAD>, 
	но ошибка при этом не возбуждается, так как Save может быть вызван из DESTROY, что является нормальным ходом исполнения. 
=cut
sub Save {
	my $self = shift;
	my $class = ref $self;

	return unless @{$self->{elements}};

	if ($self->{state} & DWHLINK) {
		return warn "OBJECT: Can't Save collection of class '$class'. Class must be a Simple descendant" unless exists $self->{simple};
		$self->_Update if exists $self->{SHAREVAL};
	} else {
		$self->_Insert;
	}
}

=begin nd
Method: Set_State ($flags)
	Поднять коллекции флаги.

	Указанные флаги поднимаются и самой коллекции, и каждому ее элементу.

Parameters:
	$flags - поднимаемые флаги <WooF::Object::Constants>

Returns:
	$self
=cut
sub Set_State {
	my ($self, $flags) = @_;

	$self->{state} |= $flags;
	
	$_->Set_State($flags) for @{$self->{elements}};
	
	$self;
}

=begin nd
Method: _Update ( )
	UPDATE всех экземпляров в базе.

Returns:
	$self
=cut
sub _Update {
	my $self = shift;

	my @fields;
	my @param = map {
		push @fields, $_;
		($_ => $self->{SHAREVAL}{$_});
	} keys %{$self->{SHAREVAL}};
	my @ph = split '', '?' x @fields;

	my $table = $self->{class}->Table;
	my $q;
	{
		local $" = ', ';
		$q = qq{
			UPDATE $table
			SET (@fields) = (@ph)
			WHERE id IN (@{$self->{simple}})
		};
	}
	$self->S->D->exec($q, @param);
	
	delete $self->{SHAREVAL};

	$self->Remove_State(MODIFIED);
}

1;
