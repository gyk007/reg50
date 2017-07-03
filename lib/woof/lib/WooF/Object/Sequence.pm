package WooF::Object::Sequence;
use base qw / WooF::Object /;

=begin nd
Class: WooF::Object::Sequence
	Базовый класс для сущностей, использующих primary key, который помимо других атрибутов включает 'n'.
	n - натуральное число, выполняющее роль последовательного непрерывного счётчика.
	Предполагается, что полностью первичный ключ должен быть определён в классе-потомке.
	n осуществляет вторичную сортировку внутри ключа.

	Все атрибуты, входящие в primary key, должны иметь атрибут key. Например,
	Класс Sequence определяет атрибут 'n'
	my %Attribute = (
		n => {key => 'ordinal'},
	);
	sub Attribute { \%Attribute }

	Класс Account наследует класс Sequence, включая все его атрибуты
	my %Attribute = (
		id_customer => {mode => 'read', key => {extern => 'NABI::User::Customer'}},
		...
	}
	sub Attribute { +{ %{+shift->SUPER::Attribute}, %Attribute} }

	В результате в таблице customer_account, которую использует класс Account, первичный ключ должен включать и 'n', и 'id_customer':
	...
	PRIMARY KEY (n, id_customer)
	...

	Потомки должны наследовать атрибуты.
	Для этого у них должен быть метод 
	sub Attribute { +{ %{+shift->SUPER::Attribute}, %Attribute} }
=cut

use strict;
use warnings;

=begin nd
Variable: my %Attribute
	Члены класса:
	n - идентификатор
=cut
my %Attribute = (
	n => {mode => 'read', key => 'ordinal'},
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.

Returns:
	Ссылку на хеш.
=cut
sub Attribute { \%Attribute }

=begin nd
Method: Prepare_key ()
	Завершить определение первичного ключа для представленного экземпляра, задав правильный порядковый номер в атрибуте 'n'.

Returns:
	n - значение, установленное полю сортировки
	undef - в случае невозможности сгенерировать первичный ключ; например, если остальные поля, входящие в первичный ключ, не определены
=cut
sub Prepare_key {
	my $self = shift;

	my $table = $self->Table or return warn "OBJECT|ERR: Can't generate primary key because of missing table.";

	my ($q, @where, @val);
	while (my ($k, $desc) = each %{$self->Key_attrs}) {
		next if $desc eq 'ordinal';
		return warn "OBJECT|ERR: The $k attribute should be defined." unless defined $self->{$k};
		push @where, "$k = ?";
		push @val, ($k => $self->{$k});
	}

	{
		local $" = ' AND ';
		$q = qq{
			SELECT n
			FROM $table
			WHERE @where
			ORDER BY n DESC LIMIT 1
		};
	}

	my $n = $self->S->D->fetch(
		$q,
		@val,
	);
	$self->{n} = $n ? ++$n->{n} : 1;
}

=begin nd
Method: Table ()
	Таблица хранения сущности в базе данных.
	Данный метод должен быть переопределён в наследующием классе.

Returns:
	undef.
=cut
sub Table { return warn "OBJECT|ERR: The Table method should be redefined in child class"; }

1;
