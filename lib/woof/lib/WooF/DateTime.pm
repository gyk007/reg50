package WooF::DateTime;

=begin nd
Class: WooF::DateTime
	Время и дата.
=cut


use strict;
use warnings;

use Time::HiRes qw/ gettimeofday /;
use Date::Parse;
use POSIX  qw/ strftime /;

use WooF::Error;

=begin nd
Variable: @nicemonth
	Русские названия месяцев.
=cut
my @nicemonth = (
	'января',
	'февраля',
	'марта',
	'апреля',
	'мая',
	'июня',
	'июля',
	'августа',
	'сентября',
	'октября',
	'ноября',
	'декабря'
);

=begin nd
Constructor: new ($time)
	Инициализирует объект WooF::DateTime.

Parameters:
	$time - время в формате PosgreSQL. Необязательный параметр.
	Если параметр отсутствует, то по умолчанию для инициализации используется текущее время.
	
Returns:
	$self
=cut
sub new {
	my ($class, $time) = @_;
	
	my ($second, $usecond);
	
	if (defined $time) {
		$second    = str2time $time;
		($usecond) = $time =~ /\.(\d+)$/;
	} else {
		$second = gettimeofday;
	}

	bless {
		second  => $second,
		usecond => $usecond || 0,
	}, $class;
}

=begin nd
Method: date ()
	Возвращает дату в формате DD.MM.YYYY
Returns:
	Строку
=cut
sub date {
	my $self = shift;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime $self->{second};

	$year += 1900;
	$mon++;

	 sprintf("%02d.%02d.%04d", $mday, $mon, $year);
}

=begin nd
Method: timestamp ()
	Время в формате TIMESTAMP(6) WITH TIME ZONE
=cut
sub timestamp {
	my WooF::DateTime $self = shift;

	return warn 'TIME: Time is not initialized' unless defined $self->{second} and defined $self->{usecond};

	my ($second, $minute, $hour, $monthday, $month, $year, $weekday, $yearday, $isdst) = localtime $self->{second};
	my $usecond = $self->{usecond};

	sprintf("%04d-%02d-%02d %02d:%02d:%02d.%06d", $year+1900, $month+1, $monthday, $hour, $minute, $second, $usecond);
}

=begin nd
Method: stamptonice ($stamp)
	Метод класса.
=cut
sub stamptonice {
	my ($class, $stamp) = @_;
	
	my ($month, $day, $hour, $min) = $stamp =~ /^\d{4}-(\d{2})-(\d{2}) (\d{2}):(\d{2})/;
	$day  =~ s/^0*//;
	$hour =~ s/^0*//;
	--$month;
	"$day $nicemonth[$month], $hour:$min";
}

=begin nd
Method: later_then ($time)
	Является ли время экземпляра более поздним, чем время аргумента.
	
Parameters:
	$time - экземпляр настоящего класса, с которым происходит сравнение.
	
Returns:
	true - в случае если время экземпляра позже
	false - в противном случае; даже в случае если равны
=cut
sub later_then {
	my ($self, $time) = @_;
	
	return
		  $self->{second}  > $time->{second} ? 1
		: $self->{usecond} > $time->{usecond};
}

1;
