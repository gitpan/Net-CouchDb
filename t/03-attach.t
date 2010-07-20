#!perl -T
use strict;
use warnings;
use Test::More tests => 6;
use MIME::Base64;

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

my $content = "This is some file content." . ("And some more" x 1000);

my $attach = $doc->attach("baz.txt", \$content);
isa_ok($attach, "Net::CouchDb::Attach");

my $encoded = encode_base64($content);
$encoded =~ s/\n//g;

is($doc->{_attachments}->{"baz.txt"}->{data}, $encoded);
