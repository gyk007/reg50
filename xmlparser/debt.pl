#!/usr/bin/perl
use strict;

use Encode;
use utf8;

use XML::Simple;
use WooF::Debug;
use ALKO::Order;

debug "START \n";

my $debt = XML::Simple->new;
my $debt = $debt->XMLin("$ENV{HOME}/data/i/debt.xml");

for my $debt (@{$debt->{debts}{debt}}) {
	my $ttn_number;
	$ttn_number = $debt->{PlatezkaVhodyashaya}{ttn_number}    if $debt->{PlatezkaVhodyashaya};
	$ttn_number = $debt->{ttn}{ttn_number}                    if $debt->{ttn};
	$ttn_number = $debt->{ReturnToMe_TTN}{ttn_number}         if $debt->{ReturnToMe_TTN};
	$ttn_number = $debt->{Prochee}{ttn_number}                if $debt->{Prochee};
	$ttn_number = $debt->{Prihod_TTN}{ttn_number}             if $debt->{Prihod_TTN};
	$ttn_number = $debt->{PlatezkaIshodyashaya}{ttn_number}   if $debt->{PlatezkaIshodyashaya};
	$ttn_number = $debt->{PrihodniyKassoviyOrder}{ttn_number} if $debt->{PrihodniyKassoviyOrder};
	$ttn_number = $debt->{KorrektirovkaDolga}{ttn_number}     if $debt->{KorrektirovkaDolga};

	if ($ttn_number) {
		my $order = ALKO::Order->Get(ttn_number => $ttn_number);

		if ($order and $debt->{sum}) {
			$order->debt($debt->{sum});
			$order->Save;
		}
	}
}

debug "END \n";

1;