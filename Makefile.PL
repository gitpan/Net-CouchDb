use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::CouchDb',
    AUTHOR              => 'David Leadbeater <dgl at dgl dot cx>',
    VERSION_FROM        => 'lib/Net/CouchDb.pm',
    ABSTRACT_FROM       => 'lib/Net/CouchDb.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP::UserAgent' => 0,
        'JSON::Any' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-CouchDb-*' },
);
