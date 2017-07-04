package ALKO::Catalog::Category;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Catalog::Category
	Категория товара.
	
	Категории организованы в дерево в классе <ALKO::Catalg>.
	
	Специальная категория с id=0 представляет невидимый корень каталога.
=cut

use strict;
use warnings;

use WooF::Debug;

use WooF::Error;

=begin nd
Variable: %Attribute
	Описание членов класса.

	Члены класса:
	description - полное описание
	name        - наименование
	products    - товары, принадлежащие данной категории
	visible     - показывается ли при выводе данная категория со всеми своими потомками
	              если любой из родителей категории скрыт, то переопределить видимость данным флагом невозможно
=cut
my %Attribute = (
	description => undef,
	name        => undef,
	products    => {
		type   => 'cache',
		extern => 'ALKO::Catalog::Product',
		maps   => {
			class  => 'ALKO::Catalog::Product::Link',
			master => 'id_category',
			slave  => 'id_product',
			set    => {face => 'face_effective'},
		},
	},
	propgroups  => {
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
	visible     => undef,
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
=cut
sub complete_products {
	my $self = shift;
	
	my $product = $self->Has('products') or return warn "Category::complete_products() requires extended products";
	
	debug 'SELF_CATEGORY=', $self;
	
	$self;
}

=begin nd
Method: Table ( )
	Таблица хранения сущности в базе данных.

Returns:
	Строку 'category'.
=cut
sub Table { 'category' }

1;
