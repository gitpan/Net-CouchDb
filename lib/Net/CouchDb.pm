package Net::CouchDb;

use warnings;
use strict;
use JSON::Any;
use LWP::UserAgent;
use CGI::Util qw(escape);
use Net::CouchDb::Database;
use Net::CouchDb::Document;

=head1 NAME

Net::CouchDb - Interface to CouchDb

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Provides an object oriented interface to the CouchDb REST/JSON API.

    use Net::CouchDb;

    my $cdb = Net::CouchDb->new(host => "localhost", port => 8888);
    $cdb->create_db("test");
    
    my $test = $cdb->db("test");

    my $doc = Net::CouchDb::Document->new;
    $doc->colours = [qw(blue green orange)];

    $test->put($doc);

=head1 METHODS

=head2 new

Creates a new Net::CouchDb object. Takes the following parameters:

=over 4

=item *

host: Hostname of server

=item *

port: Port of server

=item *

uri: Optionally specify a URI instead of host and port. (e.g. http://localhost:8888).

=item *

conn_cache: Optionally provide a LWP::ConnCache object to cache connections to CouchDb.

=back

=cut

sub new {
  my($class, %args) = @_;

  $args{uri} ||= "http://$args{host}:$args{port}";

  my $ua = LWP::UserAgent->new;
  $ua->conn_cache($args{conn_cache}) if $args{conn_cache};

  my $json = JSON::Any->new;

  return bless {
    uri  => $args{uri},
    ua   => $ua,
    json => $json
  }, shift;
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

  my $req = HTTP::Request->new($method => "$self->{uri}/$uri");

  if(defined $data && $method ne 'GET') {
    # Unbless so JSON modules don't barf..
    my %data = %$data;
    # PUT shouldn't contain _id
    delete $data{_id} if $method eq 'PUT';
    $req->content(JSON::Any->encode(\%data));
  }
  my $res = $self->{ua}->request($req);

  # Just indicate error by returning undef.
  my $obj = eval { JSON::Any->decode($res->content); };

  return wantarray ? ($res->status, $obj) : $obj;
}

=head1 AUTHOR

David Leadbeater, C<< <dgl at dgl dot cx> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-couchdb at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-CouchDb>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 David Leadbeater, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.8 or, at your option,
any later version of Perl 5 you may have available.

=cut

1;
