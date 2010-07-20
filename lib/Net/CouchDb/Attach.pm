package Net::CouchDb::Attach;

use warnings;
use strict;
use Carp;
use MIME::Base64;

=head1 NAME

Net::CouchDb::Attach - Represent an attachment to a CouchDb document.

=head1 SYNOPSIS

Representation of an attachment, this should normally be created via the
C<attach> method in L<Net::CouchDb::Document>.

=head1 METHODS

=head2 new($doc, $name)

=cut

sub new {
  my($class, $doc, $name) = @_;

  return bless {
    doc => $doc,
    name => $name,
  }, $class;
}

=head2 add($file)

Add an attachment. The parameter can be either:

=over 4

=item *

A filename, which will be opened and attached.

=item *

A scalar reference, the contents of which will be attached.

=item *

A file handle, which will be fully read and attached.

=back

=cut

sub add {
  my($self, $file) = @_;

  my $content;

  if(ref $file eq 'SCALAR') {
    $content = $file;
  } elsif(ref $file eq 'GLOB') {
    $content = \join '', <$file>;
  } else {
    open my $fh, '<', $file or croak "Opening '$file' failed: $!";
    $content = \join '', <$fh>;
  }

  $content = encode_base64($$content);
  $content =~ s/\n//g;

  $self->{doc}->{_attachments}->{$self->{name}} = {
    type => "base64",
    data => $content,
  };
}

=head2 uri

Return the URI that this attachment can be found at (as a string).

=cut

sub uri {
  my($self) = @_;
  return $self->{doc}->uri . "/" . $self->{name};
}

=head2 name

Return the name of this attachment.

=cut

sub name {
  my($self) = @_;
  return $self->{name};
}

=head2 get

Return the content of this attachment as a string.

Note this does not use the same L<LWP::UserAgent> object as the L<Net::CouchDb>
instance, so any connection cache will not be used.

=cut

sub get {
  my($self) = @_;

  return LWP::Simple::get($self->uri);
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
