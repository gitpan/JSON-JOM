package JSON::JOM::Node;

use 5.010;
use strict;
use utf8;
use Object::AUTHORITY;
use UNIVERSAL::ref;

use Carp qw[];
use Module::Pluggable
	search_path => qw[JSON::JOM::Plugins],
	require     => 1,
	sub_name    => '_plugins',
	search_dirs => [qw[lib blib/lib]],
	;
use Scalar::Util qw[];

our ($META, $AUTOLOAD, $EXTENSIONS, $TIEMAP);

BEGIN
{
	$JSON::JOM::Node::AUTHORITY = 'cpan:TOBYINK';
	$JSON::JOM::Node::VERSION   = '0.501';
}

sub import
{
	my ($class) = @_;
	foreach my $plugin ($class->_plugins)
	{
		foreach my $method ($plugin->extensions)
		{
			my ($typeof, $name, $coderef) = @$method;
			$EXTENSIONS->{$typeof}{$name} = $coderef;
		}
	}
}

sub AUTOLOAD
{
	my $function = $AUTOLOAD;
	($function) = ($function =~ /::([^:]+)$/);
	
	my ($self, @args) = @_;
	
	foreach my $x (($self->typeof, 'NODE'))
	{
		if (defined $JSON::JOM::Node::EXTENSIONS->{ $x }->{ $function })
		{
			my $coderef = $JSON::JOM::Node::EXTENSIONS->{ $x }->{ $function };
			if (ref $coderef eq 'CODE')
			{
				return $coderef->($self, @args);
			}
		}
	}
	
	warn "Undefined method: $function";
	return undef;
}

sub DESTROY {}

sub can
{
	my ($self, $method) = @_;

	if (my $code = UNIVERSAL::can($self, $method))
	{
		return $code;
	}
	
	if (defined $JSON::JOM::Node::EXTENSIONS->{ $self->typeof }->{ $method }
	&&  ref $JSON::JOM::Node::EXTENSIONS->{ $self->typeof }->{ $method } eq 'CODE')
	{
		return $JSON::JOM::Node::EXTENSIONS->{ $self->typeof }->{ $method };
	}
	
	if (defined $JSON::JOM::Node::EXTENSIONS->{'NODE'}->{ $method }
	&&  ref $JSON::JOM::Node::EXTENSIONS->{'NODE'}->{ $method } eq 'CODE')
	{
		return $JSON::JOM::Node::EXTENSIONS->{'NODE'}->{ $method };
	}
	
	return;
}

sub meta
{
	my ($self) = @_;
	$JSON::JOM::Node::META->{ $self->id } ||= {};
	return $JSON::JOM::Node::META->{ $self->id };
}

sub id
{
	my ($self) = @_;
	return Scalar::Util::refaddr($self);
}

sub _meta
{
	my ($key, $self) = (shift, shift);
	if (@_)
	{
		$self->meta->{$key} = $_[0];
	}
	return $self->meta->{$key};
}

sub typeof
{
	return;
}

sub new
{
	Carp::croak "JSON::JOM::Node is abstract - use a subclass.";
}

sub TO_JSON
{
	Carp::croak "JSON::JOM::Node is abstract - use a subclass.";
}

sub toJSON
{
	Carp::croak "JSON::JOM::Node is abstract - use a subclass.";
}

sub nodeIndex  { return _meta('nodeIndex', @_); }
sub rootNode   { return _meta('rootNode', @_); }
sub parentNode { return _meta('parentNode', @_); }

sub isRootNode
{
	my ($self) = @_;
	return $self if $self->rootNode == $self;
	return;
}

sub nodePath
{
	my ($self, $style) = @_;
	$style ||= 'jsonpath';
	
	Carp::croak "Don't know style: $style\n"
		unless $style =~ /^jsonpath$/i;
	
	if ($self->isRootNode)
	{
		return '$';
	}
	else
	{
		my $index = $self->parentNode->typeof eq 'ARRAY' 
			? ('[' . $self->nodeIndex . ']')
			: ("['" . $self->nodeIndex . "']");
		return $self->parentNode->nodePath($style) . $index;
	}
}

1;

__END__

=head1 NAME

JSON::JOM::Node - represents a node in a JOM structure

=head1 DESCRIPTION

JOM nodes have the following built-in methods. Other methods are
available in JOM plugins.

=over 4

=item * C<typeof> - returns 'HASH', 'ARRAY', 'NULL', 'BOOLEAN', 'STRING', or 'NUMBER'

=item * C<ref> - returns 'HASH', 'ARRAY' or undef

=item * C<toJSON> - returns a JSON string representing the node. This is only a full valid JSON document if ref is defined.

=item * C<rootNode> - a reference to the root node of the JOM structure.

=item * C<isRootNode> - boolean; is this the root node of the JOM structure?

=item * C<parentNode> - a reference to the parent of this node in the JOM structure.

=item * C<nodePath> - a L<JSON::Path>-compatible string pointing to this node within the JOM structure.

=item * C<nodeIndex> - the array index or object key of the parentNode where this node is located.

=item * C<meta> - returns a hashref containing metadata about this node. This is intended for use by plugins.

=item * C<id> - a string that identifies this node during a single execution context. This is intended for use by plugins.

=back

Note, the following should always be true for any JOM node C<$this>:

   $this->isRootNode
   or $this->parentNode->typeof eq 'ARRAY'
      && $this->parentNode->[ $this->nodeIndex ] == $this
   or $this->parentNode->typeof eq 'HASH'
      && $this->parentNode->{ $this->nodeIndex } == $this

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<JSON::JOM>, L<JSON::JOM::Plugins>.

L<JSON::JOM::Value>,
L<JSON::JOM::Array>,
L<JSON::JOM::Object>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010-2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

