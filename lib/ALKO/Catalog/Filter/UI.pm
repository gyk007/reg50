package ALKO::Catalog::Filter::UI;
use base qw/ WooF::Object::Simple /;

=begin nd
Class: ALKO::Catalog::Filter::UI
	Тип виджета отображения фильтра на клиенте.
	
	Конкретный тип интерфейса, определенный в данном классе, указывает клиенту
	на то, какой виждет ему следует исполльзовать для отображения и работы фильтра.
=cut

use strict;
use warnings;

=begin nd
Variable: my %Attribute
	Члены класса:
	description - описание для админа
	name        - короткое имя для ссылки из кода
=cut
my %Attribute = (
	description => undef,
	name        => undef,
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

sub Table { 'filterui' }

1;
