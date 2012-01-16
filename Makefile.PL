use 5.005000;
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	NAME              => 'LWP::UserAgent::Proxified',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/LWP/UserAgent/Proxified.pm', # finds $VERSION
	PREREQ_PM         => { 'LWP::UserAgent' => 0 }, # e.g., Module::Name => 1.1
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	(ABSTRACT_FROM  => 'lib/LWP/UserAgent/Proxified.pm', # retrieve abstract from module
	AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
