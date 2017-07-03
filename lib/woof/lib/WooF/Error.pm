package WooF::Error;
use base qw/ Exporter /;

=begin nd
Class: WooF::Error
	Фундаментальные функции обработки ошибок.

Description:
	Ошибки кладутся на стек.

	Инициализация модуля всегда происходит в самом начале <WooF::Server>.

	Модуль не является объектно-ориентированным.

	По дефолту экспортируются функции :
- <warn ( @messages )>
- <all_right ()>
- <has_error (@error)>
=cut

use strict;
use warnings;

use Time::Stamp -stamps => {dt_sep => ' ', ms => 1};

use WooF;

=begin nd
Constants: Уровни логирования:

Constant: EMERG
	Cистема неработоспособна.

	Остается только как можно более безболезнено сдохнуть и, по возможности, не вонять.
	Например, не открылся файл основного конфига.

Constant: ALERT
	Ошибка, требующая немедленной обработки.

	Обычно, нехватка или недоступность ресурсов. Есть шанс подождать и попытать счастья еще раз.

Constant: CRIT
	Критическая ошибка. Дальнейшая работа в нормальном режиме невозможна.

	Например, неразрешимое несовпадение типов данных или превышение допустимых лимитов.
	Надо прервать поток исполнения и сосредоточиться на обработке ошибки.

Constant: ERR
	Некритическая ошибка.

	Обычно решение о дальнейших действиях принимается выше.
	Скажем, обнаружилось 2 дубликата экземпляра.

Constant: WARNING
	Предупреждение. Дефолтный уровень логирования.

	На этот уровень замечательно ложатся ошибки обработки ввода пользователя. По ним можно отслеживать огрехи интерфейса или попытки взлома со стороны юзера.

Constant: NOTICE
	Примечательное событие без ошибки.

	Сделался дамп или зарегистрировался новый юзер. Каждый сам волен определять, что для него важно.

Constant: INFO
	Чисто информационное сообщение.

	Самый болтливый уровень, выше некуда.

	Все, что не попало в нижележащие уровни, но должно отразиться в логе, кладется сюда.
=cut
use constant {
	EMERG   => 'EMERG',    # 0
	ALERT   => 'ALERT',    # 1
	CRIT    => 'CRIT',     # 2
	ERR     => 'ERR',      # 3
	WARNING => 'WARNING',  # 4
	NOTICE  => 'NOTICE',   # 5
	INFO    => 'INFO',     # 6
};

our @EXPORT = qw/
	&all_right
	&has_error
	&warn
/;

=begin nd
Variable: my %Level
	Соответствие числового значения уровня символьному обозначению.
=cut
my @Level = (
	EMERG,
	ALERT,
	CRIT,
	ERR,
	WARNING,
	NOTICE,
	INFO,
);
my %Level_ix = map { ($Level[$_] => $_) } 0 .. $#Level;

# Закроем стек
##########################
#####  Private area  #####
{
=begin nd
Variable: my @stack
	Стек хранения ошибок.
	Находится в закрытой области.
=cut
	my @stack;

=begin nd
Function: all_right ()
	Проверяем чистоту стека.
	
Returns:
	1 - если нет ошибок
	0 - если ошибки есть
=cut
	sub all_right { not scalar @stack }

=begin nd
Function: bind ($node)
	Привязать стек ошибок в виде хеша в указанное место (обычно в "поток ошибок").

	Стек привязывается в виде хеша, у которого ключами являются коды ошибок,
	а значениями для всех ключей число 1.

Returns:
	Ничего осмысленного.

	Результат работы помещается непосредственно в первый фактический аргумент.

Example:
> WooF::Error::bind $server->O->{ERROR};
=cut
	sub bind($) {
		$_[0]->{$_} = 1 for @stack;
	}

=begin nd
Function: get_err_codes ()
	Получить все ошибки.

Returns:
	ссылку на массив ошибок.
=cut
	sub get_err_codes {
		my @codes = @stack;
		\@codes;
	}

=begin nd
Function: has_error (@error)
	Есть ли ошибка на стеке? Ищется хотя бы одна ошибка из списка.

Parameters:
	@error - список искомых кодов ошибок.

Returns:
	1 - если найдена хоть одна из ошибок, переданных в @error.
	undef - если ни одной из ошибок, переданных в @error, на стеке нет или если @error пуст и стек пуст.
	
=cut
	sub has_error {
		return undef unless @stack;

		my %error = map +($_ => undef), @_;

		exists $error{$_} and return 1 for @stack;

		return undef;
	}

=begin nd
Function: init ()
	Очищает локальный стек.
	Обычно вызывается один раз из <WooF::Server> для каждого клиентского запроса.
=cut
	sub init {
		@stack = ();
	}

=begin nd
Function: _push_stack ($error)
	Помещает ошибку на стек

Parameters:
	$error - код ошибки (строковой скаляр).
=cut
	sub _push_stack { push @stack, shift }

}
#####  End of Private area  #####
#################################

=begin nd
Function: _parse ($message)
	Разбирает варнинг.
	Полностью раскручивает стек текущей ошибки с тем, чтобы показать полный путь вызова.

Parameters:
	$message - Исходное сообщение.

Returns:
	$print - Печатать в лог?
	$code - Код ошибки.
	$text - Human-readabe текст для вывода в лог.
=cut
sub _parse {
	my $msg = shift;

	my ($code, $log_level, $text) = $msg =~ /
		^\s*				# Пропускаем лидирующие пробелы
		(?:
			(?:(\w*)\s*)?		# Код
			(?:\|\s*(\w*)\s*)?	# Уровень логирования
		:)?
		\s*(.*)$			# Текст ошибки
	/sx;

	$text      ||= 'Undefined error';
	$log_level ||= WARNING;

	my $level = 0;
	my @cur_stack;

	# Раскручиваем стек текущего вызова
	while ( my ($package, $file, $line) = caller $level++) {
		push @cur_stack, " $package:$line ";
	}
	$text .= " at" . join ' => ', reverse @cur_stack;

	return ($log_level, $code, $text);
}

=begin nd
Function: warn (@messages)
	Помещает ошибку на стек, печатает сообщение в лог.
	Формат сообщения: 'CODE | LEVEL : Message'. Где:
		- CODE - Код ошибки (строка). Если указан, будет помещен на стек.
		- LEVEL - Уровень логирования. Если этот уровень равен или выше установленного порога, сообщение будет напечатано в лог.
		- 'Message' - Сообщение, выводимое в лог.

	Существующие уровни логирования (LEVEL):
		- EMERG   - система неработоспособна
		- ALERT   - ошибка, требующая немедленной обработки
		- CRIT    - критическая ошибка
		- ERR     - ошибочное состояние
		- WARNING - предупреждение (дефолтный уровень для данной функции).
		- NOTICE  - нормальное, но примечательное событие, типа незлостных ошибок пользовательского ввода
		- INFO    - информация

	<WooF::Debug::debug()> никак не связан с уровнем логирования ошибок.
 	В отличии от стандартного warn, данная функция возвращает undef.
 	Надо следить за use WooF::Error чтобы warn был перегружен.
Parameters:
	@messages - Список сообщений об ошибке.
	Каждый аргумент будет конкатенирован в одну общую строку, так что одним вызовом можно установить только одну ошибку.

Returns:
	undef

Example:
(start code)
# Полный комплект: Ошибка + Уровень + Сообщение
warn 'NOUSER|ERR: User not defined';

# Ошибка + Сообщение
warn 'SYSTEM:', $!;

# Уровень + Сообщение
warn '| NOTICE : Зарегистрировался новый юзер';

# Сообщение
warn("Обращение к несуществующему ресурсу...");
(end)
=cut
sub warn {
	my ($important, $code, $text) = _parse(join ' ', @_);

	_push_stack $code if $code;

	# Печатаем в лог
	if ($Level_ix{WooF->C->{logLevel}} >= $Level_ix{$important}) {
		my $log_message;
		$log_message .= "<$code> " if $code;
		$log_message .= "$text"    if $text;
		$log_message .= "\n";

		my $script = $0 =~ /public_html(\S+)/ ? $1 : '';
		print STDERR localstamp() . " $script (pid=$$): $log_message";
		flush STDERR;
	}

	undef;
}

1;
