package WooF::DateTime::Interval;
use base qw / WooF::Object /;

=begin nd
Class: WooF::DateTime::Interval
	Временные интервалы.

	Используется для конвертации времени в формат postgres interval.
=cut

use strict;
use warnings;
use WooF::Error; 
use 5.014;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

=begin nd
Constant: SEC_PER_MIN
	Секунд в минуте

Constant: SEC_PER_HOUR
	Секунд в часе
=cut
use constant {
	SEC_PER_MIN  =>   60,
	SEC_PER_HOUR => 3600,
};

sub _sec2interval($);

=begin nd
Variable: my %Attribute
	Члены класса:
	hms - hh:mm:ss
=cut
my %Attribute = (
	hms => undef,
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
Constructor: new ($time)
	Парсит аргументы, сохраняет интервал в формате postgres interval

	Если $unit имеет значение 'minutes' то $time - количество минут, если 'seconds' то $time - количество секунд, в остальных случаях считаем, что $time - строка 'hh:mm:ss'

Parameters:
	$time - время
	$unit - единицы измерения в которых задано время.

Returns:
	$self или undef в случае ошибки
=cut
sub new {
	my ($class, $time, $unit) = @_;
	defined $time or return warn 'DATETIME: Interval Constructor requires time argument'; 
	$unit ||= 'hms';

	my $self = $class->SUPER::new;

	given  ($unit) {
		when (/^min/) { $self->{hms} = _sec2interval $time * SEC_PER_MIN }
		when (/^sec/) { $self->{hms} = _sec2interval $time }
		when (/^hms$/){ $self->{hms} = $time if $time =~ /^\d{2}:\d{2}:\d{2}$/ }
	}
	defined $self->{hms} or return warn "DATETIME: Incorrect time format. Arguments: time = $time; $unit = $unit";

	$self;
}

=begin nd
Method: _sec2interval ($sec)
	Ковертировать секунды в строку вида hh:mm:ss

Parameters:
	sec - количество секунд(целое)

Returns:
	interval - строка вида hh:mm:ss или undef в случае ошибки
=cut
sub _sec2interval($) {
	my $sec = shift;
	defined $sec and $sec =~ /^(\d+)$/ or return warn "DATETIME: Incorrect time format. Arguments: $sec";

	my $s = $1 % SEC_PER_MIN;
	my $m = int($1 % SEC_PER_HOUR / SEC_PER_MIN);
	my $h = int($1 / SEC_PER_HOUR);
	
	sprintf("%02d:%02d:%02d", $h, $m, $s);
}

=begin nd
Method: to_hms
	Получить интервал в формате hms

Returns:
	interval - строка вида hh:mm:ss
=cut
sub to_hms {	
	+shift->{hms};
}

=begin nd
Method: to_min
	Получить интервал в минутах

Returns:
	min - количество минут
=cut
sub to_min {
	int(+shift->to_sec / SEC_PER_MIN);
}

=begin nd
Method: to_sec
	Получить интервал в секундах

Returns:
	sec - количество секунд
=cut
sub to_sec {
	my $self = shift;

	my ($h, $m, $s) = split(/:/, $self->{hms});

	$h * SEC_PER_HOUR + $m * SEC_PER_MIN + $s;
}

1;
