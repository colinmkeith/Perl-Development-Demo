use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Demo::Poller',
    AUTHOR              => 'Colin Keith <colinmkeith@gmail.com>',
    VERSION_FROM        => 'lib/Demo/Poller.pm',
    ABSTRACT_FROM       => 'lib/Demo/Poller.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Try::Tiny'  => 0,
        'Net::SNMP'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Demo-Poller-*' },
);
