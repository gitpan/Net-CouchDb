#!perl -T
use strict;
use warnings;
use lib qw(. t);

use Test::More tests => 9;
use Net::CouchDb;
use MockCouch;

my $db_name = "net-couchdb-test-05";

my $couchdb = MockCouch->new(host => "localhost", port => 5984);

ok($couchdb->create_db($db_name), "create");

my $db = $couchdb->db($db_name);
ok($db->isa("Net::CouchDb::Database"), "isa database");

my $doc = $db->new_doc;

ok($doc->isa("Net::CouchDb::Document"), "isa document");

$doc->test = "This is some testing text.";

my $res = $doc->create;
ok($res->{ok}, "Document created");

ok($res->{id}, "Got id $res->{id}");
ok($res->{rev}, "Got rev $res->{rev}");

is($res->{id}, $doc->id, "ID updated");


ok($couchdb->delete_db($db_name), "delete");
ok(!(grep { $_ eq $db_name } $couchdb->all_dbs), "check delete");

