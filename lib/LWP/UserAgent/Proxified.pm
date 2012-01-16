package LWP::UserAgent::Proxified;

use strict;
use base 'LWP::UserAgent';

our $VERSION = '0.00';

sub new {
	my ($class, %opts) = @_;
	
	my $proxylist = delete $opts{proxylist};
	my $self = $class->SUPER::new(%opts);
	
	$self->{proxylist} = $proxylist;
	return $self;
}

sub simple_request {
	my $self = shift;
	
	if (@{$self->{proxylist}}) {
		my $i = int rand @{$self->{proxylist}};
		$i-- unless $i%2 == 0;
		
		$self->proxy($self->{proxylist}[$i], $self->{proxylist}[$i+1]);
	}
	
	return $self->SUPER::simple_request(@_);
}

1;
