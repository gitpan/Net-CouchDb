package Net::CouchDb;

use warnings;
use strict;
use Carp;
use JSON qw(to_json from_json);
use LWP::UserAgent;
use LWP::ConnCache;
use CGI::Util qw(escape);
use Net::CouchDb::Database;
use Net::CouchDb::Document;

use constant DEBUG => $ENV{COUCH_DEBUG} || 0;

=head1 NAME

Net::CouchDb - Interface to CouchDb

=cut

our $VERSION = '0.04';

=head1 NO LONGER MAINTAINED

Please note this module is B<no longer maintained>. I recommend you use
L<CouchDB::Client> instead (or L<AnyEvent::CouchDB> if that is closer to your
needs).

=head1 SYNOPSIS

Provides an object oriented interface to the CouchDb REST/JSON API.

    use Net::CouchDb;

    my $cdb = Net::CouchDb->new(host => "localhost", port => 5984);
    $cdb->debug(1);
    $cdb->create_db("test");

    my $test = $cdb->db("test");

    my $doc = $test->new_doc;
    $doc->colours = [qw(blue green orange)];

    $doc->create;

=head1 METHODS

=head2 new

Creates a new Net::CouchDb object. Takes the following parameters:

=over 4

=item *

host: Hostname of server (defaults to localhost).

=item *

port: Port of server (defaults to 5984).

=item *

uri: Optionally specify a URI instead of host and port. (e.g. http://localhost:5984).

=item *

conn_cache: Either provide a LWP::ConnCache object to cache connections to CouchDb,
or set to 0 to disable connection caching. If not supplied Net::CouchDb will
automatically use a per-instance cache.

=back

=cut

sub new {
  my($class, %args) = @_;

  $args{host} ||= 'localhost';
  $args{port} ||= 5984;

  $args{uri} ||= "http://$args{host}:$args{port}";

  my $ua = LWP::UserAgent->new;

  # Default to a conncache unless set to 0 to disable.
  $ua->conn_cache(exists $args{conn_cache} ? $args{conn_cache} : LWP::ConnCache->new)
    unless exists $args{conn_cache} && !$args{conn_cache};

  my $self = bless {
    uri  => $args{uri},
    ua   => $ua,
  }, $class;

  $self->debug(exists $args{debug} ? $args{debug} : DEBUG);

  $self;
}

=head2 db

Open/connect to a specific database. Returns a L<Net::CouchDb::Database> object.

=cut

sub db {
  my($self, $database) = @_;
  return Net::CouchDb::Database->new($self, $database);
}

=head2 database

Alias for db.

=cut

*database = \&db;

=head2 create_db($name)

Create a new database.

=cut

sub create_db {
  my($self, $db) = @_;
  my $res = $self->call(PUT => "$db/");
  return $res && $res->{ok};
}

=head2 all_dbs 

Return a list of all databases

=cut

sub all_dbs {
  my($self) = @_;
  my $db = $self->call(GET => "_all_dbs");
  return wantarray ? ($db && ref $db eq 'ARRAY' ? @$db : ()) : $db;
}

=head2 delete_db

Delete a database.

=cut

sub delete_db {
  my($self, $db) = @_;
  my $res = $self->call(DELETE => "$db/");
  return $res && $res->{ok};
}

=head2 server_info

Returns a data structure with the information from the couchdb "/" URI
(notably the version).

=cut

sub server_info {
  my $self = shift;
  my $res = $self->call(GET => '');
  $res
}

=head2 debug

Set or get the debug flag (defaults to 0, higher values gives more
debug output). This requires that the L<Data::Dump> module is installed.

This can also be enabled via the C<COUCH_DEBUG> environment variable.

=cut

sub debug {
    my $self = shift;
    if (@_) {
        my $old_debug = $self->{debug};
        $self->{debug} = shift;
        if (!$old_debug and $self->{debug}) {
            require Data::Dump;
        }
    }
    $self->{debug} || 0;
}

=head2 log(debug_level, message, [message, ...])

Log a debug message at C<debug_level>.

=cut

sub log {
    my $self = shift;
    return unless (($self->{debug} || 0) >= shift);
    carp Data::Dump::dump(@_);
}

=head2 call($method, $uri, $data)

Make a REST/JSON call. Normally you should use a more specific method,
but this provides low-level access if needed.

=over 4

=item *

$method is the HTTP method to use.

=item *

$uri is the HTTP URI to request.

=item *

$data is a reference which will be converted to JSON data if the request
expects one. For a GET request it is converted into URI parameters.

=back

Returns a reference to the returned JSON data in scalar context, in
array context returns the HTTP status and the reference.

=cut

sub call {
  my($self, $method, $uri, $data) = @_;

  if(defined $data && $method eq 'GET') {
    $uri .= "?" .
      join ';', map { escape($_) . "=" . escape($data->{$_}) } keys %$data;
  }

  $self->log(1, " -> $method $self->{uri}/$uri");

  my $req = HTTP::Request->new($method => "$self->{uri}/$uri");

  if(defined $data && $method ne 'GET') {
    # Unbless so JSON modules don't barf..
    my %data = %$data;
    # PUT shouldn't contain _id
    delete $data{_id} if $method eq 'PUT';
    # remove undef _id from POST
    delete $data{_id} unless defined $data{_id};

    $req->content(to_json(\%data));
  }
  my $res = $self->{ua}->request($req);

  $self->log(5, $res->content);

  # Just indicate error by returning undef.
  my $obj = eval { $res->is_error ? undef : from_json($res->content); };
  warn "Error decoding content: $@" if $@;

  return wantarray ? ($res->code, $obj) : $obj;
}

=head2 uri

Return the URI that this instance is pointing at.

=cut

sub uri {
  my($self) = @_;
  return $self->{uri};
}

=head1 AUTHOR

David Leadbeater, C<< <dgl at dgl dot cx> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-couchdb at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-CouchDb>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 DEVELOPMENT

There is a git repository available at L<git://code.d.cx/Net-CouchDb>, which
can be viewed at L<http://code.d.cx/?p=Net-CouchDb.git>.

=head1 COPYRIGHT & LICENSE

Copyright 2007 David Leadbeater, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.8 or, at your option,
any later version of Perl 5 you may have available.

=cut

1;
