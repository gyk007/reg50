package ALKO::Server;
use base qw/ WooF::Server Exporter /;
WooF::Server->import(qw/ OK FAIL REDIRECT PAGELESS /);
our @EXPORT = qw/ OK FAIL REDIRECT /;
=begin nd
Class: ALKO::Server
	Класс, наследующий WooF::Server::PSGI
=cut

use strict;
use warnings;

use ALKO::Session;
use ALKO::Client::Shop;
use ALKO::Client::Merchant;
use DateTime;
use Digest::MD5 qw(md5_hex);
use WooF::Debug;
our @ISA;

=begin nd
Constructor: new ()
    Получает экземпляр сервера.
=cut
sub new {
    my $class = shift;

    my $server = $class->SUPER::new(@_);

    # Меняем родителя
    @ISA = ref $server if $server->isa('WooF::Server::PSGI');

    bless $server, $class;
}

=begin nd
Method: authenticate ()
	Авторизация
=cut
sub authenticate {
	my $self = shift;
	my ($I, $O) = ($self->I, $self->O);

	return $self->_auth_by_token    if $I->{token};
	return $self->_auth_by_password if $I->{password} and $I->{login};
	return $self->fail('AUTH: Authentication failed');
}

=begin nd
Method: _auth_by_token
	авторизация по токену
=cut
sub _auth_by_token {
	my $self = shift;
	my ($I, $O) = ($self->I, $self->O);

	my $dt = DateTime->now();
	my $session = ALKO::Session->Get(token => $I->{token});

	# Проверяем существование сессии
	return $self->fail('AUTH: Authentication failed') unless $session;

	# Обновляем время последнего визита
	$session->ltime($dt);

	delete $I->{token};

	$O->{SESSION} = $session;

	1;
}

=begin nd
Method: _auth_by_password
	авторизация по логину и паролю
=cut
sub _auth_by_password {
	my $self = shift;
	my ($I, $O) = ($self->I, $self->O);
	my $dt = DateTime->now();

	# Удаляем пробелы
	$I->{login}     =~ s/[\s]//g;
	$I->{password}  =~ s/[\s]//g;

	# Получаем хэш пароля (Пока это не работает)
	#$I->{password} = md5_hex($I->{password});

	my $merchant = ALKO::Client::Merchant->Get(password => $I->{password}, email => $I->{login});

	# Проверяем существование пользователя
	return $self->fail('AUTH: Authentication failed') unless $merchant;

	# Создаем токен
	my $token;
	my @all = split(//, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890');
	map { $token .= $all[rand @all]; } (0..14);

	# Удаляем старые сесси
	my $sessions = ALKO::Session->All(id_merchant => $merchant->id)->List;
	if($sessions) {
		for(@$sessions) {
			$_->Remove;
		}
	}

	# Создаем сессию
	my $session = ALKO::Session->new({
		token       => $token,
		id_merchant => $merchant->id,
		ctime       => $dt,
		ltime       => $dt
	})->Save;

	delete $I->{password};
	delete $I->{login};

	$O->{SESSION} = $session;

	1;
}

1;