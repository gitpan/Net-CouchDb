package Net::CouchDb::Document;

use warnings;
use strict;
use Net::CouchDb::Attach;
use Carp;

# Mapping from this document to the database it belongs in.
# Rather than storing the mapping within the object we store the mapping in a hash here,
# this saves storing it within the object (so the user is free to use the keys
# how they wish and avoids overhead such as tieing in the general case).
my %db_mapping;

=head1 NAME

Net::CouchDb::Document - Represent a CouchDb document

=head1 SYNOPSIS

Provides an object oriented interface to the CouchDb REST/JSON API.

=head1 METHODS

=head2 new([$id][, $fields[, $database]])

Creates a new instance of a document in memory, all parameters are optional.

If an ID is not provided one will be generated automatically by CoudhDb when
the document is created.

A hash reference is expected for the fields.

If the database is provided then it will be used for the ->C<create> and
->C<update> methods.

Note: The C<new> method merely creates an instance of the object; it does not
touch the database.

=cut

sub new {
  my($class, $id, $fields, $database) = @_;

  if((ref $id || !defined $id) && !defined $database) { # Actually fields
    $database = $fields;
    $fields = $id;
    $id = undef;
  }

  my $self = bless {
    defined $id ? (_id => $id) : (),
    defined $fields ? %$fields : ()
  }, $class;

  if(defined $database) {
    $db_mapping{sprintf "%x", $self} = $database;
  }

  return $self;
}

=head2 id

Getter/setter for the ID.

=cut

sub id : lvalue {
  my($self, $id) = @_;
  $self->{_id} = $id if defined $id;
  $self->{_id};
}

=head2 rev

Getter/setter for the revision.

=cut

sub rev : lvalue {
  my($self, $rev) = @_;
  $self->{_rev} = $rev if defined $rev;
  $self->{_rev};
}

=head2 uri

Return a URI to this document. Requires document to have been created.

=cut

sub uri {
  my($self) = @_;
  my $db = $db_mapping{sprintf "%x", $self};
  croak "No database specified for document" unless defined $db;

  return $db->uri . "/" . $self->id;
}

=head2 create

Create this document (using the database specified in C<new>).

If an ID has not been previously supplied CouchDb will create one
and the object will be updated to reflect this.

=cut

sub create {
  my($self) = @_;
  my $db = $db_mapping{sprintf "%x", $self};

  croak "No database to create document in" unless defined $db;

  $db->post($self);
}

=head2 update

Update this document (using the database specified in C<new>).

=cut

sub update {
  my($self) = @_;
  my $db = $db_mapping{sprintf "%x", $self};

  croak "No database to update document in" unless defined $db;

  $db->put($self);
}

=head2 attach([$name[, $file]])

List, add or retrieve attachments.

With no parameters returns a list of attached files.

With a name returns a L<Net::CouchDb::Attach> object.

With file specified as well passes the file parameter to the C<add> method of
L<Net::CouchDb::Attach>.

=cut

sub attach {
  my($self, $name, $file) = @_;

  if(!defined $name) {
    my @attach = keys %{$self->{_attachments}};
    return wantarray ? @attach : \@attach;
  }

  my $attach = Net::CouchDb::Attach->new($self, $name);

  $attach->add($file) if defined $file;

  return $attach;
}

=head2 Anything else

This object provides an autoloaded method for any parameter that is set,
therefore any field can be set like so:

  $doc->foo = "bar";

Because C<id>, C<rev>, C<uri>, C<attach>, C<create> and C<update> are taken by
the above methods you should use syntax like:

  $doc->{create} = 1;

If you want to give parameters those names.

=cut

our $AUTOLOAD;

sub AUTOLOAD : lvalue {
  my($self, $content) = @_;
  my $name = ($AUTOLOAD =~ /::([^:]+)$/)[0];

  if(defined $content) {
    $self->{$name} = $content;
  }
  $self->{$name};
}

sub DESTROY {
  delete $db_mapping{sprintf "%x", $_[0]};
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
