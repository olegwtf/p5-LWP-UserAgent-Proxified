package LWP::UserAgent::Proxified;

use strict;
use Carp;
use base 'LWP::UserAgent';
use List::Util;
use Net::Proxy::Type;

our $VERSION = '0.00';

sub new {
	my ($class, %opts) = @_;
	
	my $proxylist    = delete $opts{proxylist};
	my $proxyrand    = delete $opts{proxyrand};
	my $proxyshuffle = delete $opts{proxyshuffle};
	my $proxyset_cb  = delete $opts{proxyset_cb};
	
	my $self = $class->SUPER::new(%opts);
	
	if ($proxylist) {
		for (my $i=0, my $l=@$proxylist; $i<$l; $i+=2) {
			if ($proxylist->[$i+1] !~ m@^\w+://@) {
				# form file
				open my $fh, '<', $proxylist->[$i+1]
					or carp "`$proxylist->[$i+1]': $!";
				my @list = map{s/\s+//g;$_} <$fh>
					or carp "`$proxylist->[$i+1]' is empty";
				$proxylist->[$i+1] = shift @list;
				if (@list) {
					push @$proxylist, map {($proxylist->[$i], $_)} @list;
				}
				close $fh;
			}
		}
	}
	$self->{proxylist}    = $proxylist;
	$self->{proxyrand}    = $proxyrand;
	$self->{proxyshuffle} = $proxyshuffle;
	$self->{proxyset_cb}  = $proxyset_cb;
	$self->{current_proxy} = 0;
	
	return $self;
}

sub filter_proxylist {
	my ($self) = @_;
	my $checker = Net::Proxy::Type->new(strict => 1);
	my @to_remove;
	
	for (my $i=0; $i<@{$self->{proxylist}}; $i+=2) {
		my ($host) = $self->{proxylist}[$i+1] =~ m@^\w+://(.+)@;
		my $type = $checker->get($host);
		if ($type == Net::Proxy::Type::DEAD_PROXY || 
		    $type == Net::Proxy::Type::UNKNOWN_PROXY) {
			push @to_remove, $i, $i+1;
		}
	}
	
	for (my $i=$#to_remove; $i>=0; $i--) {
		splice @{$self->{proxylist}}, $to_remove[$i], 1;
	}
}

sub simple_request {
	my $self = shift;
	my $request = $_[0];
	
	my ($proxy_scheme, $proxy);
	if (!$self->{was_redirect} && $self->{proxylist} && @{$self->{proxylist}}) {
		if ($self->{proxyrand}) {
			my $i = int rand @{$self->{proxylist}};
			$i-- unless $i % 2 == 0;
			
			$proxy_scheme = $self->{proxylist}[$i];
			$proxy        = $self->{proxylist}[$i+1];
		}
		else {
			if ($self->{current_proxy} >= @{$self->{proxylist}}) {
				$self->{current_proxy} = 0;
				if ($self->{proxyshuffle}) {
					my @index = List::Util::shuffle 0..@{$self->{proxylist}}/2-1;
					my @copy  = @{$self->{proxylist}};
					for (my $i=0; $i<@index; $i++) {
						$self->{proxylist}[$i*2]   = $copy[$index[$i]*2];
						$self->{proxylist}[$i*2+1] = $copy[$index[$i]*2+1];
					}
				}
			}
			
			$proxy_scheme = $self->{proxylist}[$self->{current_proxy}];
			$proxy        = $self->{proxylist}[$self->{current_proxy}+1];
			$self->{current_proxy} += 2;
		}
		
		if (defined $self->{proxyset_cb} and ref $self->{proxyset_cb} eq 'CODE') {
			my @rv = $self->{proxyset_cb}->($self, $request, $self->{proxylist}, $proxy_scheme, $proxy);
			if (@rv == 2) {
				($proxy_scheme, $proxy) = @rv;
			}
		}
		
		$self->proxy($proxy_scheme, $proxy);
	}
	
	my $response = $self->SUPER::simple_request(@_);
	$self->{was_redirect} = $response->is_redirect && _in($request->method, $self->requests_redirectable);
	return $response;
}

sub _in($$) {
	my ($what, $where) = @_;
	
	foreach my $item (@$where) {
		return 1 if ($what eq $item);
	}
	
	return 0;
}

1;
