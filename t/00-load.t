#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::CouchDb' );
}

diag( "Testing Net::CouchDb $Net::CouchDb::VERSION, Perl $], $^X" );
