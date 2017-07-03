#! /usr/bin/perl

#
# Этот скрипт выводит список инсталляционных скриптов,
# которые еще не были выполнены на данной машине.
#

use strict;
use warnings;

use constant {
	STEPDIR => 'step',
	STEPLOG => 'steps.completed',
};

# Читаем в массив из лога уже выполненные step'ы
my @done;
if (-r STEPLOG) {
	open(my $fh, '<', STEPLOG) or die "Can't open steps file: $!";
	@done = <$fh>;
	close $fh or die "Can't close steps file: $!";
} else {
    open(my $fh, '>', STEPLOG) or die "Can't create steps file: $!";
}

# Изо всех степов отбираем только те, для которых нет записи в логе
chomp @done;
my %done = map {$_ => undef} @done;
my @todo = grep ! exists $done{$_}, map m{^.*/(.*)}, glob STEPDIR . '/*.pl';

local $" = "\n";
print @todo ?  "Missing steps:\n@todo\n" : "No errors found\n";
