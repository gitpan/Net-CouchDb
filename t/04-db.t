#!perl -T
use strict;
use warnings;
use lib qw(. t);

use Test::More tests => 18;
use Net::CouchDb;
use MockCouch;

my $couchdb = MockCouch->new(host => "localhost", port => 5984);

my $server_info = $couchdb->server_info;

ok($server_info->{version}, "got version ($server_info->{version})");

my $dbs = $couchdb->all_dbs;
# TODO: check that the response is reasonable

ok($couchdb->isa("Net::CouchDb"), "isa couchdb");

my $db_name = "net-couchdb-test";

ok($couchdb->create_db($db_name), "create");

my $db = $couchdb->db($db_name);
ok($db->isa("Net::CouchDb::Database"), "isa database");

ok(my $db_info = $db->database_info, "get database info");
is($db_info->{doc_count}, 0, "document count is 0");

my $doc = Net::CouchDb::Document->new("test1");

ok($doc->isa("Net::CouchDb::Document"), "isa document");

$doc->test = "This is some testing text.";

my $res = $db->put($doc);
ok($res->{ok}, "Document inserted");

ok($res->{id} eq "test1", "Got id $res->{id}");
ok($res->{rev}, "Got rev $res->{rev}");

my $get = $db->get("test1");

is_deeply($get, { %$doc, _rev => $res->{rev} }, "Returned doc is the same");

$doc->foo = [qw(foo bar baz etc)];

my $res2 = $db->put($doc);
ok($res2->{ok}, "put updated");

ok(my ($doc1) = $db->get($doc, rev => $res->{rev}), "get doc1");
ok(my ($doc2) = $db->get($doc, rev => $res2->{rev}), "get doc2");

ok(!$doc1->{foo} && $doc1->{_rev} eq $res->{rev}, "first revision");
ok($doc2->{foo} && $doc2->{_rev} eq $res2->{rev}, "second revision");

ok($couchdb->delete_db($db_name), "delete");
ok(!(grep { $_ eq $db_name } $couchdb->all_dbs), "check delete");

