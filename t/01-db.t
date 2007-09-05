#!perl -T
use Test::More;
use Net::CouchDb;

my $couchdb = Net::CouchDb->new(host => "localhost", port => 8888);

my $dbs = $couchdb->all_dbs;

if(!$dbs) {
  plan skip_all => "Did not find couchdb, skipping live tests";
  exit;
} else {
  plan tests => 13;
}

ok($couchdb->isa("Net::CouchDb"), "isa couchdb");

my $db_name = "net-couchdb-test-$$-" . time;

ok($couchdb->create_db($db_name), "create");

my $db = $couchdb->db($db_name);
ok($db->isa("Net::CouchDb::Database"), "isa database");

my $doc = Net::CouchDb::Document->new("test1");

ok($doc->isa("Net::CouchDb::Document"), "isa document");

$doc->test = "This is some testing text.";

my $res = $db->put($doc);
ok($res->{ok}, "Document inserted");

ok($res->{_id} eq "test1", "Has Id $res->{_id}");
ok($res->{_rev}, "Has rev $res->{_rev}");

my $get = $db->get("test1");

is_deeply($get, { %$doc, _rev => $res->{_rev} }, "Returned doc is the same");

$doc->foo = [qw(foo bar baz etc)];

my $res2 = $db->put($doc);
ok($res2->{ok}, "put updated");

my($doc1) = $db->get($doc, rev => $res->{_rev});
my($doc2) = $db->get($doc, rev => $res2->{_rev});

ok(!$doc1->{foo} && $doc1->{_rev} eq $res->{_rev}, "first revision");
ok($doc2->{foo} && $doc2->{_rev} eq $res2->{_rev}, "second revision");

ok($couchdb->delete_db($db_name), "delete");
ok(!(grep { $_ eq $db_name } $couchdb->all_dbs), "check delete");

