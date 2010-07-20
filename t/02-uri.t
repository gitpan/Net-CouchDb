#!perl -T
use strict;
use warnings;
use Test::More tests => 7;

use_ok("Net::CouchDb");

# Note these tests should be offline -- no queries should be made to this.
# Hence the (hopefully) invalid host/port.
my $couchdb = Net::CouchDb->new(host => "localhost", port => 1);

$couchdb->debug($ENV{COUCH_DEBUG});

isa_ok($couchdb, "Net::CouchDb");

my $db = $couchdb->db("foo");
isa_ok($db, "Net::CouchDb::Database");

my $doc = $db->new_doc;
isa_ok($doc, "Net::CouchDb::Document");
$doc->id = "bar";

is($doc->uri, "http://localhost:1/foo/bar");

my $attach = $doc->attach("baz.txt");
isa_ok($attach, "Net::CouchDb::Attach");

is($attach->uri, "http://localhost:1/foo/bar/baz.txt");
