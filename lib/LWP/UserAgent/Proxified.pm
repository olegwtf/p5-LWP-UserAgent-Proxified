package LWP::UserAgent::Proxified;

use strict;
use base 'LWP::UserAgent';
use List::Util;

our $VERSION = '0.00';

sub new {
	my ($class, %opts) = @_;
	
	my $proxylist    = delete $opts{proxylist};
	my $proxyrand    = delete $opts{proxyrand};
	my $proxyshuffle = delete $opts{proxyshuffle};
	my $proxyset_cb  = delete $opts{proxyset_cb};
	my $self = $class->SUPER::new(%opts);
	
	$self->{proxylist}    = $proxylist;
	$self->{proxyrand}    = $proxyrand;
	$self->{proxyshuffle} = $proxyshuffle;
	$self->{proxyset_cb}  = $proxyset_cb;
	$self->{current_proxy} = 0;
	
	return $self;
}

sub simple_request {
	my ($self, $request) = @_;
	
	my ($proxy_scheme, $proxy);
	if (!$self->{was_redirect} && @{$self->{proxylist}}) {
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
					@{$self->{proxylist}} = List::Util::shuffle @{$self->{proxylist}};
				}
			}
			
			$proxy_scheme = $self->{proxylist}[$self->{current_proxy}];
			$proxy        = $self->{proxylist}[$self->{current_proxy}+1];
			$self->{current_proxy} += 2;
		}
		
		if (defined $self->{proxyset_cb} and ref $self->{proxyset_cb} eq 'CODE') {
			my @rv = $self->{proxyset_cb}->($request, $self->{proxylist}, $proxy_scheme, $proxy);
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
