package Net::CouchDb::Document;

use warnings;
use strict;

=head1 NAME

Net::CouchDb::Doc - Represent a CouchDb document

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Provides an object oriented interface to the CouchDb REST/JSON API.

=head1 METHODS

=head2 new([$id[, $fields]])

Creates a new instance of a document, the ID and fields are optional.

=cut

sub new {
  my($class, $id, $fields) = @_;
  return bless {
    _id => $id,
    defined $fields ? %$fields : ()
  }, $class;
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

=head2 Anything else

This object provides an autoloaded method for any parameter that is set,
therefore any field can be set like so:

  $doc->foo = "bar";

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

=head1 AUTHOR

David Leadbeater, C<< <dgl at dgl dot cx> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 David Leadbeater, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.8 or, at your option,
any later version of Perl 5 you may have available.

=cut

1;
