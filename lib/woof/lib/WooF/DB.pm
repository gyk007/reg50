package WooF::DB;
use base qw/ WooF::Object /;

=begin nd
Class: WooF::DB
	Работа с Базой Данных.
=cut

use strict;
use warnings;

use DBI;

use WooF::Debug;
use WooF::Error;

=begin nd
Variable: my %Attribute
	Члены класса:
dbh - дескриптор соединения
sth - дескриптор запроса
connect_type - тип подключения к базе ('share' по дефолту)
=cut
my %Attribute = (
	dbh => undef,
	sth => undef,
	connect_type => {default => 'share'},
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.

Returns:
	ссылку на хеш
=cut
sub Attribute { \%Attribute }

=begin nd
Constructor: new (%attributes)
	Берет из конфига параметры соединения к БД, подключается, сохраняет дескриптор в атрибуте dbh.

	Существуют два типа подключения, контролируемых атрибутом 'connect_type', 'share' и 'transaction'.
	'share' используется для выполнения неизолированных от других частей кода запросов, в то время, как
	'transaction' предназначен для обособленных транзакций, за счет невозможности совместного использования дескриптора подключения.
	Дефолтным типом подключения является 'share'.

Returns:
	экземпляр - если подключение установлено
	undef - в противном случае
=cut
sub new {
	my $self = shift->SUPER::new(@_);
	my $C = $self->C;

	my $connection = $C->{db}{connection}{$self->{connect_type}};
	my $connect = $connection->{method};
	my $dsn = "dbi:Pg:database=$C->{db}{name};host=$C->{db}{location}{host};port=$C->{db}{location}{port}";

	my (%options, $k, $v);
	$options{$k} = $v->{content} while ($k, $v) = each %{$connection->{option}};

	$self->{dbh} = DBI->$connect($dsn, $C->{db}{role}{user}{login}, $C->{db}{role}{user}{password}, \%options)
		or return warn 'SYSTEM|ALERT:', DBI->errstr;

	$self;
}

=begin nd
Method: exec ($q, @param)
	Выполнить запрос.

	Сначала выполняется DBI->prepare(), потом биндятся параметры, и сам запрос выполняется столько раз, сколько необходимо.

Params:
	$q     - строка запроса или объект запроса <WooF::DB::Query>

	@param - массив значений, если запрос содержит placeholders.
	Массив состоит из псевдохешей (просто пар) вида field_1=>value_1, field_2=>value_2, field_name=>[value_1, value_2, ..., value_n], ...
	Если в позиции значения (как в последнем случае) оказывается ссылка на массив, будет выполнено несколько последовательных запросов с каждым из значений.

	Имена полей в массиве пока являются избыточными, но в будущем будут задействованы при определении типа данных поля.

Returns:
	Дескриптор выполненного, но не финализированного запроса $sth.
=cut
sub exec {
	my ($self, $q, @param) = @_;
	
	return warn "DBASE: No query specified" unless $q;
	
	if ($q->isa('WooF::DB::Query')) {
		@param = $q->val unless @param;
		$q = $q->print;
	}
	debug DL_SQL, 'DB::exec Query=', $q, ";\nDB::exec QParam=", \@param;
	
	return warn "DBASE: Odd number in param hash" if @param % 2;
	my $paramN = @param / 2;   # Количество параметров, упакованных во входном массиве

	my $sth = $self->{dbh}->prepare($q);
	return warn "DBASE: Can't prepare query: $q: ", $sth->errstr unless $sth;

	return warn "DBASE: Placeholders number don't match values number" unless $sth->{NUM_OF_PARAMS} == $paramN;

	# определяем сколько раз надо выполнить запрос
	my $execN;
	my ($k, $v);
	for (my $i = 0; $i < @param; ++$i) {
		if ($i % 2) {
			$v = $param[$i];
		} else {                    # в позиции ключа (четные индексы) просто запоминаем ключ
			$k = $param[$i];
			next;
		}
		next unless ref $v eq 'ARRAY';
		
		return warn "DBASE: Empty param's array" unless @$v;

		if ($execN) {
			return warn "DBASE: Distinct param's array numer" unless $execN == @$v;
		} else {
			$execN = @$v;
		}
	}
	$execN ||= 1;

	for (1 .. $execN) {
		my $ix = $_ - 1;                   # текущий индекс элемента в массиве, находящемся в позиции значения.

		# биндим параметры по порядку
		for (1 .. $paramN) {
			my $iv = $_ * 2 - 1;       # индекс текущего элемента во входном массиве параметров - второго элемента пары 'ключ-значение'
			my $current = $param[$iv]; # значение текущего элемента во входном массиве, находящегося в позиции значения хеша

			# реальное значение, очищенное от упаковки. То, которое будет биндиться.
			my $value = ref $current eq 'ARRAY' ? $current->[$ix] : $current;

			$sth->bind_param($_, $value) or return warn "DBASE: Can't bind value $value in query $q: ", $sth->errstr;
		}

		$sth->execute or return warn "DBASE: Can't execute statement $q: ", $sth->errstr;
	}

	$self->{sth} = $sth;
}

=begin nd
Method: fetch ($q, @param)
	Выполнить запрос и получть результирующий набор.
	
Parameters:
	$q     - строка запроса или объект запроса <WooF::DB::Query>
	@param - то же самое, что и в <fetch_all ($Q, @param)>.

Returns:
	Ссылку на массив хешей в случае спиского контекста вызыва.
	
	Ссылку на хеш, представляющего первую (единственную в идеале) результирующую строку.
=cut
sub fetch {
	my $rc = &fetch_all;
	my $self = shift;
	
	if (wantarray) {
		$rc
	} else {
		$self->{sth}->finish;
		$rc->[0];
	}
}

=begin nd
Method: fetch_all ($Q, @param)
	Выполнить запрос и получть результирующий набор.
	
Parameters:
	$Q     - строка запроса
	@param - почти то же самое, что и в <exec ($q, @param)>, но в выборке ссылка на объекты недопустимы.

Returns:
	Ссылку на массив хешей в случае спиского контекста вызыва.

=cut
sub fetch_all {
	my ($self, $Q, @param) = @_;
	
	$self->{sth} = $self->exec($Q, @param);

	$self->{sth}->fetchall_arrayref({});
}


1;
