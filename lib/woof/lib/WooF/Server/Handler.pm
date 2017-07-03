package WooF::Server::Handler;
use base qw/ WooF::Object /;

=begin nd
Class: WooF::Server::Handler
	Обработчик сервера производит всю основную работу по обработке запроса.
	
	Обработчик состоит из процедуры, выполняющей логику программы, и драйвера ввода,
	определяющего допустимость и обязательность входных параметров.
	
	В скором времени обработчик будет дополнен и драйвером вывода, который будет для каждого
	объекта, полученного в результате работы процедуры, пропускать на выход только допустимые
	поля.
=cut

use strict;
use warnings;

use Clone qw/ clone /;

use WooF::Error;

=begin nd
Variable: %Attribute
	Описание членов класса, поскольку являемся потомками <WooF::Object>

	Члены класса:
	call        - основная процедура, выполняющая логику и обычно помещающая результаты в поток вывода
	iflow        - копия входного потока; нужен клон т.к. копия будет изменена
	input       - драйвер ввода; описывает дозволенные в элементе allow поля
	k           - текущий ключ текущей ноды (ключ хеша offer)
	name        - имя обработчика в скрипте; должно быть уникально в пределах скрипта
	offer       - текущий хеш при разборе ввода
	offer_stack - путь разбора ввода в виде стека ссылок на хеши от потока до текущего, не включая текущий; текущий хеш хранится в атрибуте offer
	page        - имя шаблона; файл шаблона состоит из имени и суффикса; специальное значение PAGELESS указывает на то, что шаблона нет
	              и вывод из обработчика осуществлен быть не может, только редирект или замена цепочки вызова
	rule        - текущий массив из структуры, определяющей разрешения драйвера
	rule_stack  - путь по вложенным массивам разрешений; дополняется и уменьшается синхронно с путем в iflow (атрибут offer_stack)
	v           - значение текущеего элемента текущей ноды (значение элемента хеша offer)
	
	Элемент 'stable' в описании атрибута, будучи установленным в true, отменяет очищение атрибута в <cleanup>.
	Нет смысла создавать каждый раз заново основную процедуру, имя хендлера, и т.п., так как эти значения не меняются никогда в процессе работы сервера.
=cut
my %Attribute = (
	call        => {mode => 'read', stable => 1},
	iflow       => undef,
	input       => {stable => 1},
	k           => undef,
	name        => {mode => 'read', stable => 1},
	offer       => undef,
	offer_stack => {default => []},
	page        => {mode => 'read', stable => 1},
	rule        => undef,
	rule_stack  => {default => []},
	v           => undef,
);

=begin nd
Method: Attribute ()
	Доступ к хешу с описанием членов класса.

Returns:
	ссылку на хеш
=cut
sub Attribute { \%Attribute }

=begin nd
Method cleanup ()
	Очистить все члены класса, кроме "стабильных", установив дефолтные значения, если таковые имеются.
	
	После окончания работы хендлер не умирает. Чтобы данные от предыдущего запроса не попадали в новый
	их надо сбрасывать. Иначе стеки будут расти в размере на неактуальных данных.
=cut
sub cleanup {
	my $self = shift;
	
	while (my ($attr, $v) = each %Attribute) {
		unless (exists $v->{stable} and $v->{stable}) {
			if (defined $v) {
				if (exists $v->{default}) {
					$self->{$attr} = ref $v->{default} ? clone $v->{default} : $v->{default};
				}
			} else {
				undef $self->{$attr};
			}
		}
	}
}

=begin nd
Method: in ($iflow)
	Запустить контроллер ввода.
	
	Если указаны допустимые входные параметры, проверить поток ввода на отсутствие
	лишних элементов. В случае обнаружения, вернуть ошибку.
	
	Описание допустимых параметров находится в %{input=>allow}

	Производится синхронный обход двух деревьев: потока и описания в контроллере.
	Деревья различаются по структуре. Ведущим деревом при обходе является поток:
	берется параметр потока и в дереве контроллера ищется ему соответствие.
	
	"Нодой" считается пара "ключ-значение" в хеше потока. При этом значением может быть как действительное
	значение аргумента, так и ссылка на вложенный хеш. Подразумевается, что пустых хешей в потоке быть не может.
	
Returns:
	true  - в случае удовлетворения потоком условий, определенных в контроллере
	false - если поток проверку не прошел
=cut
sub in {
	my $self = shift;
	my $iflow = $self->S->I;
	
	# ограничения не определены скриптом
	exists $self->{input} and exists $self->{input}{allow} or return 1;
	
	$self->{iflow} = clone $iflow;
	$self->{rule} = $self->{input}{allow};
	push @{$self->{rule_stack}}, $self->{rule};
	$self->{offer} = $self->{iflow};

	while (my ($k, $v) = $self->_next_node) {
		# Есть ли в текущем массиве разрешений элемент с текущим ключом потока?
		# Если нет, то функция проверку провалила,
		# в противном случае получаем индекс элемента, чтобы затем проверить
		# элемент-значение соответствующее элементу-ключу.
		my $key_index;
		while (my ($i, $allow) = each @{$self->{rule}}) {
			next if ref $allow;

			if ($k eq $allow) {
				$key_index = $i;
				keys @{$self->{rule}};  # reset each_iterator for later use starting at first item
				last;
			}
		}
		defined $key_index or return warn "INPUT: Incorrect params: k=$k; v=$v";
		my $val_index = $key_index + 1;

		if (ref $v) {
			# Поток содержит вложенный хеш.
			# Если в разрешениях ключ стоит последним, значит ожидается простое значение, что является ошибкой, так как ссылки на массив нет.
			# Также ошибкой будет, если после ключа не окажется ссылки на массив.
			return warn "INPUT: Hash found where value expected: k=$k; v=$v"
				if $val_index == @{$self->{rule}};
			
			my $next_rule = $self->{rule}[$val_index];
			my $ref_arr = ref $next_rule;
			return warn "INPUT: Hash found where value expected: k=$k; v=$v"
				if not defined $ref_arr or $ref_arr ne 'ARRAY';

			push @{$self->{rule_stack}}, $self->{rule};
			$self->{rule} = $next_rule;
			next;
		} else {
			next if $val_index == @{$self->{rule}} or not ref $self->{rule}[$val_index];
			
			return warn "INPUT: Value found where hash expected: k=$k; v=$v";
		}
	}
	
	return 1;
}

=begin nd
Method: _next_node ()
	Очередной шаг в проходе дерева аргументов потока.
	
	На каждом шаге возвращается пара ключ-значение текущего хеша.
	Если текщий хеш больше не имеет элементов, подбирается и устанавливается текущим в атрибут offer
	подходящий хеш.
	
	Если весь поток перебран, возвращается пустой список.
	
	Метод расчитывает на то, что поток не имеет пустых хешей.

Returns:
	($k, $v) - пара текущего хеша
	пустой список - если элементы потока закончились
=cut
sub _next_node {
	my $self = shift;

	if (ref $self->{v}) {
		push @{$self->{offer_stack}}, $self->{offer};
		$self->{offer} = $self->{v};
		return ($self->{k}, $self->{v}) = each %{$self->{offer}};            # очередной хеш потока
	} else {
		if (my ($k, $v) = each %{$self->{offer}}) {
			return ($self->{k}, $self->{v}) = ($k, $v);
		} else {                                                             # конец текущего хеша
			while ($self->{offer} = pop @{$self->{offer_stack}}) {
				$self->{rule} = pop @{$self->{rule_stack}};
				if (my ($k, $v) = each %{$self->{offer}}) {
					return ($self->{k}, $self->{v}) = ($k, $v);
				}
			}
			return ();                                                   # поток иссяк, конец разбора
		}
	}
}

1;
