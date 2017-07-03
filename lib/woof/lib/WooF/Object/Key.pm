package WooF::Object::Key;
use base qw / WooF::Object /;

=begin nd
Class: WooF::Object::Key
	Контейнер для ключей класса.
=cut

use strict;
use warnings;

use WooF::Util;

=begin nd
Variable: my %Attribute
	Члены класса:
	target       - имя класса, чьи ключи здесь собраны
	attr_desc   - ссылка на хеш, в котором ключами служат имена атрибутов-ключей класса, а значениями описания этих ключей, которые могут быть просто undef
	sorted_list - ссылка на массив имен ключевых полей упорядоченных в соответствии с тем, как они индексируются в БД
=cut
my %Attribute = (
	target      => undef,
	attr_desc   => {mode => 'read', default => {}},
	sorted_list => {mode => 'read', default => []},
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.
	Может вызываться и как метод экземпляра, и как метод класса.

Returns:
	Ссылку на хеш.
=cut
sub Attribute { +{ %Attribute } }

=begin nd
Constructor: new ($target)
	Создает экземпляр класса и заполняет его информацией о ключах выбранного объекта.
	
	В конструкторе сразу вычисляются все нужные ему данные и запоминаются результаты в своих членах класса. Так что вся тяжелая работа происходит только один раз.

Parameters:
	$target - имя класса, чьи ключи необходимо получить.

Returns:
	Ссылку на экземпляр класса <WooF::Object::Key> и undef в случае ошибки
=cut
sub new {
	my ($class, $target) = @_;

	my $self = $class->SUPER::new(target => $target);

	#Сохраняем результат в переменную т.к. в противном случае each будет вызывать каждый раз метод по новой, начинать обходить новый хэш и зацикливаться
	my $Attr = $target->Attribute;
	while (my ($attr, $desc) = each %{$Attr}) {
		$self->{attr_desc}{$attr} = $desc->{key} if defined $desc and exists $desc->{key};
	}

	$self->{sorted_list} = $self->_primary_sorted;

	return warn "OBJECT|ERR: No Keys defined for class $target" unless $self->{attr_desc} and $self->{sorted_list};

	$self;
}

=begin nd
Method: primary_sorted
	Запросить базу данных о составе составного первичного ключа

Returns:
	Ссылка на массив имен ключевых полей упорядоченных в соответствии с тем, как они индексируются в БД
=cut
sub _primary_sorted {
	my $self = shift;

	my $target = $self->{target};
	my $table = $target->Table or return warn "OBJECT|ERR: There is no Table method in the $target class";

	my $q = qq{
		SELECT
			a.attname
		FROM
				pg_index i
			JOIN
				pg_attribute a 
					ON
							a.attrelid = i.indrelid
						AND
							a.attnum = ANY(i.indkey)
		WHERE
				i.indrelid = ?::regclass
			AND
				i.indisprimary
		ORDER BY
			a.attnum
	};

	my $q_res = $target->S->D->fetch_all(
		$q,
		table => $table,
	);

	[ map $_->{attname}, @{$q_res} ];
}

1;