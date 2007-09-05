package Net::CouchDb::Database;

use warnings;
use strict;

=head1 NAME

Net::CouchDb::Database - Interface to a CouchDb database

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Represents a single couchdb database.

This should be created via Net::CouchDb.

=head1 METHODS

=head2 new

=cut

sub new {
  my($class, $couchdb, $database) = @_;
  return bless {
    couchdb => $couchdb,
    database => $database,
  }, $class;
}

=head2 get($id [, rev => 'revision'])

Get a document with a specific ID, takes additional parameters for revision.

If rev is provided returns a list of the specified revisions, 

=cut

sub get {
  my($self, $id, %args) = @_;

  my $uri = ref $id ? $id->{_id} : $id;

  my $res = $self->call(GET => $uri, \%args);

  if(exists $args{rev} && $res->{docs}) {
    my @docs =
      map { Net::CouchDb::Document->new($_->{_id}, $_) } @{$res->{docs}};
    return wantarray ? @docs : \@docs;
  }

  return $res;
}

=head2 put($doc)

Add or update a named document.

(put and post are similar, put is only useful if you want to ensure any
document inserted already has an id specified.)

=cut

sub put {
  my($self, $doc) = @_;
  my $res = $self->call(PUT => $doc->id, $doc);
  if($res && $res->{ok}) {
    # Update the revision
    $doc->_rev = $res->{_rev};
  }
  return $res;
}

=head2 post($doc)

Add or update a document.

=cut

sub post {
  my($self, $doc, %args) = @_;
  my $res = $self->call(POST => "", $doc);
  if($res && $res->{ok}) {
    # Update the revision
    $doc->_rev = $res->{_rev};
    $doc->_id = $res->{_id} unless $doc->{_id};
  }
  return $res;
}

=head2 delete($id)

Delete a document with the given ID

=cut

sub delete {
  my($self, $id) = @_;
  my $res = $self->call(DELETE => $id);
  return $res;
}

=head2 all_docs

Return a list of all documents.

=cut

sub all_docs {
  my($self, %args) = @_;
  my $res = $self->call(GET => "_all_docs", \%args);
  return $res;
}

=head2 call($method, $uri, $data)

Make a REST/JSON call, automatically adding the correct database to the URI.
See L<Net::CouchDb::call> for parameters.

=cut

sub call {
  my($self, $method, $uri, $data) = @_;
  return $self->{couchdb}->call($method, "$self->{database}/$uri", $data);
}

=head1 AUTHOR

David Leadbeater, C<< <dgl at dgl dot cx> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 David Leadbeater, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.8 or, at your option,
any later version of Perl 5 you may have available.

=cut

1;
