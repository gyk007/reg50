package WooF;

=begin nd
Class: WooF
	Ядро проекта.
	
	Дает доступ к конфигу. Любой класс, нуждающийся в использовании данных конфига, должен наследовать данному классу.
=cut

use strict;
use warnings;

use WooF::Config;

=begin nd
Method: C ()
	Доступ к конфигурационным параметрам.

Returns:
	Ссылку на хеш с параметрами:
(start code)
config = {
	apache  => '/home/pupkin/project/opt/iglow.local',
	webserv => '/home/pupkin/project/webserv',
	install => '/home/pupkin/project/webserv/install',
	lib => {
		woof => '/home/pupkin/iglow/woof/lib',
	},
	db => {
		name => 'project_db',
		location => {
			host => 'localhost',
			port => 5432,
		},
		role =>
			admin => {
				login    => 'admin',
				password => 'secret',

			},
			user => {
				login    => 'user',
				password => 'secret',
			},
		},
		connection => {
			share => {
				method => 'connect_cached',
				option => {
					AutoCommit => {content => 1},
					RaiseError => {content => 0},
					PrintError => {content => 1},
				},
			},
			transaction => {
				method => 'connect',
				option => {
					AutoCommit => {content => 0},
					RaiseError => {content => 0},
					PrintError => {content => 1},
				},
			},
			homealone => {
				method => 'connect',
				option => {
					AutoCommit => {content => 1},
					RaiseError => {content => 0},
					PrintError => {content => 1},
				},
			},
		},
	},
	logLevel => 'INFO',
	debug => {
		output => 'On',
		layer => {
			SRV => {},
			APP => {},
		},
	},
};
(end code)
=cut
sub C { $WooF::Config::DATA }

=begin nd
Method: D()
	Доступ к объекту Базы Данных.

Returns:
	Объект Базы Данных <WooF::DB>
=cut
sub D { WooF::DB->new }

=begin nd
Method: S ()
	Доступ к объекту сервера <WooF::Server>.

	В случае, когда код запущен не из под FastCGI, объекта <WooF::Server::Server> не существует,
	и доступ к Базе Данных через член класса Сервера невозможен. Чтобы каждый раз не проверять конструкции типа
> $self->S->D
	на наличие объекта сервера, подменяем его именем базового класса и получаем доступ к Базе через данный класс.

Returns:
	объект Сервера  - если Сервер запущен
	строку 'WooF' - в противном случае
=cut
sub S { $WooF::Server::Server or $WooF::Server::PSGI::Server or 'WooF' }

1;
