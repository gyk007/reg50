package ALKO::Catalog::Category;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Catalog::Category
	Категория товара.

	Категории организованы в дерево в классе <ALKO::Catalog>.

	Специальная категория с id=0 представляет невидимый корень каталога.
=cut

use strict;
use warnings;

use 5.014;
no warnings 'experimental::smartmatch';

use WooF::Error;
use WooF::Object::Collection;
use WooF::Object::Constants;
use WooF::Debug;
use ALKO::Catalog::Property;
use ALKO::Catalog::Property::Value;
use ALKO::Catalog::Property::Type;
use ALKO::Catalog::Property::Type::Engine;
use ALKO::Catalog::Filter::UI;
use ALKO::Catalog::Filter::Arg;
use ALKO::Catalog::Filter::Arg::PropLink;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	description      - полное описание
	filter           - коллекция свойств с установленными по ним в данной категории фильтрами

	name             - наименование
	parents          - коллекция родительских категорий от корня до текущей, включая текушую
	products         - товары, принадлежащие данной категории
	propgroups       - группы свойств привязанные непосредственно к данной категрии; наследованные не включены
	visible          - показывается ли при выводе данная категория со всеми своими потомками
	                   если любой из родителей категории скрыт, то переопределить видимость данным флагом невозможно
=cut
my %Attribute = (
	description      => undef,
	filter           => {type => 'cache'},
	groups_effective => {mode => 'read/write', type => 'cache'},
	name             => undef,
	parents          => {type => 'cache'},
	products         => {
	                        mode   => 'read',
	                        type   => 'cache',
	                        extern => 'ALKO::Catalog::Product',
	                        maps   => {
	                                      class  => 'ALKO::Catalog::Product::Link',
	                                      master => 'id_category',
	                                      slave  => 'id_product',
	                                      set    => {face => 'face_effective'},
	                        },
	},
	propgroups      => {
	                        mode   => 'read',
	                        type   => 'cache',
	                        extern => 'ALKO::Catalog::Property::Group',
	                        maps   => {
	                                      class  => 'ALKO::Catalog::Property::Group::Link',
	                                      master => 'id_category',
	                                      slave  => 'id_propgroup',
	                                      set    => {
	                                                    face    => 'face_effective',
	                                                    joint   => 'joint',
	                                                    visible => 'visible',
	                                                    weight  => 'weight',
	                                      },
	                        },
	},
	visible         => undef,
);

=begin nd
Method: Attribute ( )
	Доступ к хешу с описанием членов класса.

	Может вызываться и как метод экземпляра, и как метод класса.
	Наследует члены класса родителей.

Returns:
	ссылку на описание членов класса
=cut
sub Attribute { +{ %{+shift->SUPER::Attribute}, %Attribute} }

=begin nd
Method: complete_products ( )
	Получить полный список товаров в категории.

	Все товары, со всеми свойствами и их значениями. Карточка товара для всех товаров в категории.

Returns:
	$self
	$undef - в случае ошибки
=cut
sub complete_products {
	my $self = shift;

	my $product   = $self->Has('products')   or return warn "Category::complete_products() requires extended products";
	my $propgroup = $self->Has('propgroups') or return warn "Category::complete_products() requires extended propgroups";
	my $parents   = $self->parents;

	# проходим от корневой категории до текущей, собирая все встретившиеся категории
	for ($parents->List) {
		# когда коллекция научится расширяться, можно будет заменить на получение групп до цикла
		$_->Expand('propgroups');

		# на первом проходе (корневая категория) собранных групп еще нет, создаем под них атрибут в else
		if ($self->groups_effective) {
			# каждую группу либо добавляем, если такой еще не было, либо переопределяем уже имющуюся
			for ($_->propgroups->List) {
				if (my $must_redefine = $self->groups_effective->First_Item(id => $_->{id})) {
					$must_redefine->joint($_->joint);
				} else {
					$self->groups_effective->Push($_);
				}
			}
		} else {
			# можно будет избавиться от явного создания коллекции, если научить сеттеры в Object создавать
			# коллекцию автоматически при Push в неопределенный cache
			$self->groups_effective(WooF::Object::Collection->new('ALKO::Catalog::Property::Group')->Set_State(DWHLINK));

			# в корневой категории наследовать нечего, просто добавлем группы из нее
			$self->groups_effective->Push($_->propgroups->List);
		}
	}

	# эталонные свойства для копирования в каждый продукт
	$self->groups_effective->Expand('properties');

	# cобрали все свойства с включенными фильтрами
	my $filter = WooF::Object::Collection->new('ALKO::Catalog::Property');
	for my $group ($self->groups_effective->List) {
		for ($group->properties->List) {
			next unless $_->filters and $_->id_filterui;

			$filter->Push($_);
		}
	}

	# добавить в фильтры имя и аргументы
	my $ui = $filter->Hash('id_filterui');
	my $uis = ALKO::Catalog::Filter::UI->All(id => [keys %$ui])->Hash;
	for ($filter->List) {
		$_->filterui($uis->{$_->id_filterui});

		my $link = ALKO::Catalog::Filter::Arg::PropLink->All(id_propgroup => $_->id_propgroup, n_property => $_->n);
		for ($link->List) {
			my $arg = ALKO::Catalog::Filter::Arg->Get($_->id_filterarg);
			$_->filterarg($arg);
		}
		$_->filterarg($link);
	}

	# Получаем описание для типа свойства 'unitable'
	my $unitable_t = ALKO::Catalog::Property::Type->Get(name => 'unitable');
	# Получаем название классов для свойств, значение которых находятся в отдельной таблице
	my $unitable = ALKO::Catalog::Property::Param::Value->All(id_proptype => $unitable_t->id)->Hash('id_propgroup');

	# Создаем структуру: $unitable_hash->{ид группы свойств}{номер свойства в группе} = имя класса
	my $unitable_hash;
	for my $id_propgroup (keys %$unitable) {
		for (@{$unitable->{$id_propgroup}}){
			$unitable_hash->{$id_propgroup}{$_->{n_propgroup}} = $_->{value};
		}
	}

	# развесистый хеш значений свойств с обособленными ключам, чтобы легче дампить
	my %value;
	# Свойства, значения которых находятся в таблице
	# Получим структуру такого типа:  $table_prop->{название класса для свойсва}{ид в таблице этого свойства} = значение этого свойсва
	my $table_prop;
	for my $prop (ALKO::Catalog::Property::Value->All(id_product => [$self->products->List('id')])->List) {
		$value{id_product}{$prop->id_product}{id_propgroup}{$prop->id_propgroup}{n_property}{$prop->n_property} = $prop;
		# Создаем структуру $table_prop->{название класса для свойсва}{ид в таблице этого свойства} = undef
		$table_prop->{$unitable_hash->{$prop->id_propgroup}{$prop->n_property}}{$prop->val_int} = undef if $unitable_hash->{$prop->id_propgroup}{$prop->n_property};
	}

	# Заполняем структуру $table_prop значениями из таблиц
	for my $table_class (keys %$table_prop) {
		# Временный массив для ид
		my @id_temp;
		push  @id_temp, $_  for keys %{$table_prop->{$table_class}};

		# Подгружаем нужный модуль
		my $module = $table_class;
		$module =~ s!::!/!g;
		$module .= '.pm';
		require $module or return warn "OBJECT: Can'n load module $module";

		# Заполняем структуру
		$table_prop->{$table_class}{$_->id} = $_->name for ($table_class->All(id =>\@id_temp)->List);
	}

	my $prop_t = ALKO::Catalog::Property::Type->All->Hash('id');

	# копируем в каждый товар все свойства и заполняем значениями
	for my $product ($self->products->List) {
		# копируем группы
		$product->properties($self->groups_effective->Clone(id => 'id')->Set_State(NOSYNC));

		for my $dst_group ($product->properties->List) {
			# копируем свойства
			my $src_group = $self->groups_effective->First_Item(id => $dst_group->id);
			$dst_group->properties($src_group->properties->Clone(id_propgroup => 'id_propgroup', n => 'n')->Set_State(NOSYNC));

			# устанавливаем каждому свойству значение
			for my $prop ($dst_group->properties->List) {
				if (
						exists $value{id_product}{$product->id}
					and
						exists $value{id_product}{$product->id}{id_propgroup}{$prop->id_propgroup}
					and
						exists $value{id_product}{$product->id}{id_propgroup}{$prop->id_propgroup}{n_property}{$prop->n}
				) {
					# заводим движок
					my $proptype = $prop_t->{$prop->id_proptype};

					my $engine_class = 'ALKO::Catalog::Property::Type::Engine::' . $proptype->[0]->class;
					my $module = $engine_class;
					$module =~ s!::!/!g;
					$module .= '.pm';
					require $module or return warn "OBJECT: Can'n load module $module";
					my $engine = $engine_class->new(property => $prop);

					# передаем движку хранимое значение
					my $store_t;
					given ($engine->store_t) {
						when ('integer') {$store_t = 'val_int'}
						when ('float')   {$store_t = 'val_float'}
						when ('decimal') {$store_t = 'val_dec'}
						default {return warn "CATALOG: Stored value type not defined"}
					}

					$engine->store($value{id_product}{$product->id}{id_propgroup}{$prop->id_propgroup}{n_property}{$prop->n}->$store_t);

					# движок вернул результаты своей работы
					$prop->value($engine->operate($table_prop));

					# вычисляем начальные значения фильтра
					if ($prop->filters and $prop->id_filterui) {
						my $propfilter = $filter->First_Item(id_propgroup => $prop->id_propgroup, n => $prop->n);
						for ($propfilter->filterarg->List) {
							my $arg = $_->filterarg;

							given ($arg->name) {
								when ('min') {
									if (defined $arg->value) {
										$arg->value($prop->value) if $prop->value < $arg->value;
									} else {
										$arg->value($prop->value);
									}
								}
								when ('max') {
									if (defined $arg->value) {
										$arg->value($prop->value) if $prop->value > $arg->value;
									} else {
										$arg->value($prop->value);
									}
								}
							}
						}
					}
				}
			}
		}
	}

	$self->{filter} = $filter;

	$self;
}

=begin nd
Method: has_products ( )
	Содержит ли категория товары.

Returns:
	количество товаров в категории - если есть
	0                              - если нет
=cut
sub has_products {
	my $self = shift;

	$self->Expand('products') unless $self->products;

	scalar @{$self->products->List};
}

=begin nd
Method: parents ( )
	Достать массив всех родительских категорий от корня до текущей.

	Экземпляры коллекции категорий-родителей расположены в порядке "сверху вниз" - от
	корня до текущей включительно. Коллекция будет привязана к атрибуту parents (хранится в $self->{extend}{parents}).

Returns:
	Коллекцию категорий от корня до текущей включительно.
=cut
sub parents {
	my $self = shift;
	my $class = ref $self;

	return $self->{extend}{parents} if exists $self->{extend} and exists $self->{extend}{parents};

	my $parents = $self->{extend}{parents} = WooF::Object::Collection->new($class)->Set_State(DWHLINK);

	# порядок выборки будет от текущей категории вверх до корня
	my $q = q{
		WITH RECURSIVE parents(top, down) as (
				SELECT top, down
				FROM category_graph
				WHERE down = ?
			UNION ALL
				SELECT g.top, g.down
				FROM parents p left join category_graph g on p.top = g.down
				WHERE p.down != ?
		)
		SELECT top, down FROM parents;
	};
	my $rows = $self->S->D->fetch_all($q, id_category => $self->{id}, id_category => $ALKO::Catalog::ROOT);

	$parents->Push($class->Get($_)) for map $_->{down}, reverse @$rows;

	$parents;
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'category'.
=cut
sub Table { 'category' }

1;
