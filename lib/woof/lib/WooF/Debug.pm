package WooF::Debug;
use base qw/ Exporter /;

=begin nd
Class: WooF::Debug
	Управление отладочными сообщениями.

	Любое отладочное сообщение принадлежит конкретному слою. Слои полностью независимы друг от друга.

	Существующие слои:
	DL_APP - слой "приложения". Предназначен для вывода отладки, относящейся к работе конкретного скрипта. Поскольку скриптов много, не стоит оставлять подобный уровень в коммитах без крайней необходимости. В противном случае отладка станет экстремально запутанной. Дефолтный слой.
	DL_SRV - слой "сервера". Отладка по ходу работы основной логики Сервера (<WooF::Server>).
	DL_SQL  - слой Базы Данных. Показывает запросы с параметрами.

	Сообщения, относящиеся к слою, выводятся только в том случае, если в основном конфигурационном файле (woof/lib/WooF/Config/global.xml) в секции 'debug' имеется элемент <layer> с соответствующим именем слоя без префикса 'DL_'. Например: <layer name="SRV"/>.
	Отключить вывод всех сообщений можно установив в конфиге в секции <debug> элемент <output> в значение 'Off'.

Example:
(start code)
# Вывод дампа
debug $hash_ref;

# Привязка к слою
debug DL_SRV, "\$var=$var; exemplar=", $exemplar;
(end)
=cut

use strict;
use warnings;

use Data::Dumper;
use Time::Stamp -stamps => {dt_sep => ' ', ms => 1};

use WooF::Config;

use vars qw/ @EXPORT /;
@EXPORT = qw/ &debug DL_APP DL_SRV DL_SQL /;

=begin nd
Constant: Prefix
	не экспортируется

Constant: DefaultLayer
	Если в функции <debug (@messages)> не указан слой, будет использоваться данный.

Constants: Экспортируемые слои отладки:

Constant: DL_APP
		слой приложения (дефолтный)

Constant: DL_SRV
		логика работы сервера

Constant: DL_SQL
		база данных
=cut
use constant {
	# Слои отладки
	DL_APP => 'DL_APP',
	DL_SRV => 'DL_SRV',
	DL_SQL => 'DL_SQL',

	# Префикс, используемый для слоев отладки в коде
	Prefix => 'DL_',

	# Дефолтный слой отладки
	DefaultLayer => 'DL_APP',
};

=begin nd
Variable: %Layer
	Хеш с числовыми значениями слоев
=cut
my %Layer = (
	DL_APP => 0b0001,
	DL_SRV => 0b0010,
	DL_SQL => 0b0100,
);

=begin nd
Function: debug (@messages)
	При включенной отладке соответствующего слоя печатает отладочные сообщения в лог.

Parameters:
	Список вывода в лог.

	Если элемент списка является ссылкой, будет выведен дамп.

	Будет предпринята попытка интерпретации первого элемента списка как слоя отладки.
=cut
my $prefix = Prefix;
sub debug {
	my $layer = _is_layer($_[0]) ? shift : DefaultLayer;

	# Вырезаем префикс, чтобы в лог печатались слои вывода в том виде, в котором они укзаны в конфиге
	(my $short) = $layer =~ /^$prefix(\w+)$/o;
	
	return if _mute($layer);

	my $script = $0 =~ /public_html(\S+)/ ? $1 : ''; # название скрипта
	my $output = localstamp() . " $script (pid=$$) Debug[$short]: ";
	for my $arg (@_) {
		$arg = '' unless defined $arg;
		$output .= ref $arg ? Dumper $arg : $arg;
	}
	$output .= "\n";

	print STDERR $output;
	flush STDERR;
}

=begin nd
Function: _is_layer ($candidate)
	Является ли первый (и единственный) переданный параметр указанием слоя отладки

Returns:
	TRUE - если слой
	FALSE - в противном случае
=cut
sub _is_layer { not ref $_[0] and exists $Layer{$_[0]} }

=begin nd
Function: _mute ($layer)
	Подавлять ли вывод дебага?

Returns:
	TRUE - если вывод подавлен
	FALSE - если надо выводить
=cut
sub _mute {
	my $current = $Layer{+shift};

	my $conf = $WooF::Config::DATA->{debug};

	return 1 unless $conf->{output} eq 'On';

	# Получаем флаги слоев
	my $layers = 0;

	# в зависимости от количества флагов $conf->layer имеет разную структуру:
	# либо один элемент хеша с ключом 'name',
	# либо хеш, в котором фалги являются ключами, а значениями - пустые хеши
	if (exists $conf->{layer}{name}) {
		my $debug = Prefix . $conf->{layer}{name};
		exists $Layer{$debug} and $layers += $Layer{$debug};
	} else {
		exists $Layer{Prefix . $_} and $layers += $Layer{Prefix . $_} for keys %{$conf->{layer}};
	}

	not $current & $layers;
}

1;
