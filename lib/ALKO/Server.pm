package ALKO::Server;
use base qw/ WooF::Server /;
=begin nd
Class: ALKO::Server
	Класс, наследующий WooF::Server::PSGI
=cut

use strict;
use warnings;

use WooF::Server::Constants;
use ALKO::Session;
use ALKO::Client::Merchant;

=begin nd
Method: authenticate ()
	Авторизация
=cut
sub WooF::Server::PSGI::authenticate {
	1;
}



1;