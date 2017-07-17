package WooF::Object::Simple;
use base qw / WooF::Object /;

=begin nd
Class: WooF::Object::Simple
	Базовый класс для сущностей, имеющих в качестве первичного ключа единственный атрибут с именм 'id'.
	
	Потомки должны наследовать атрибуты.
	Для этого у них должен быть метод 
	sub Attribute { +{ %{+shift->SUPER::Attribute}, %Attribute} }
=cut

use strict;
use warnings;
no warnings 'experimental';

use WooF::Object::Constants;

=begin nd
Variable: my %Attribute
	Члены класса:
	id      - идентификатор
=cut
my %Attribute = (
	id => {key => 'default', mode => 'read'},
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.

Returns:
	Ссылку на хеш.
=cut
sub Attribute { \%Attribute }

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
		push @attrs, $_;
		
		($_ => $self->{$_});
	} grep $self->{$_}, keys %{$self->Attribute};
	
	my @ph = split //, '?' x @attrs;

	my $q;
	{
		local $" = ', ';

		$q = @attrs ? 
				  "INSERT INTO $table (@attrs) VALUES (@ph) RETURNING id"
				: "INSERT INTO $table (id) VALUES (default) RETURNING id";
	}

	$self->{STATE} = DWHLINK;

	$self->{id} = $self->S->D->fetch($q, @values)->{id};
}

=begin nd
Method: Generate_Key ( )
	Получает ключ из базы, устанавливает экземпляру, и возвращает его.

Returns:
	Сгенерированный id
=cut
sub Generate_Key {
	my $self = shift;
	
	my $table = $self->Table;
	my $q = qq{SELECT nextval('${table}_id_seq')};

	$self->{id} = $self->S->D->fetch($q)->{nextval};
}

=begin nd
Method: Get_keys ( )
	Генерирует первичные ключи.

Parameters:
	n - количество ключей.

Returns:
	Cсылку на массив [{id => id1}, {id => id2}, ...etc]
=cut
sub Get_keys {
	my ($class, $n) = @_;

	my $table = $class->Table;
	my $q = qq{SELECT generate_key('${table}_id_seq', $n) AS id};

	my $keys = $class->S->D->fetch_all($q);
}

=begin nd
Method: Get (@in)
	Получить экземпляр класса, удовлетворяющего условиям, описанным в @in.
	Если в массиве @in только один элемент, то считается что это id искомого экземпляра.

Parameters:
	@in - условия выборки

Returns:
	Экземпляр класса в случае наличия единственного экземпляра.
=cut
sub Get {
	my $either = shift;

	if (@_ == 1 and ref $_[0] ne 'HASH') {
		return $either->SUPER::Get(id => $_[0]);
	} else {
		return $either->SUPER::Get(@_);
	}
}

=begin nd
Method: Key ( )
	Получить описание ключа.

Returns:
	Ссылку на хеш, с ключом id и значением описания ключа.
=cut
sub Key_attrs { {id => +shift->Attribute->{id}} }

=begin
Method: Prepare_key ( )
	 Готовит ключ для вставки.
	 Поскольку в базе стоит последовательность по дефолту, то и делать ничего не надо.
	 
Returns:
	true
=cut
sub Prepare_key { 1 }

=begin nd
Method: Sorted_keys
	Получить ссылку на массив имен ключевых полей упорядоченных в соответствии с тем, как они индексируются в БД.

Returns:
	Ссылку на массив.
=cut
sub Sorted_keys { [ 'id' ] }

=begin nd
Method: Table ( )
	Чисто виртуальный метод, должен быть перегружен потомком.

Returns:
	undef
	Возбуждает ошибку, так как не был перегружен потомком.
=cut
sub Table {
	my $self = shift;
	my $class = ref $self;
	
	return warn "OBJECT: Table method must be redefined in subclass $class";
}

1;
