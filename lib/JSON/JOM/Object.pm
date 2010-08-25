package JSON::JOM::Object;

use 5.008;
use common::sense;

use Carp;
use Module::Pluggable search_path => qw[JSON::JOM::Plugins], require => 1, sub_name => '_plugins', search_dirs => [qw[lib blib/lib]];
use Scalar::Util qw[];

our ($META, $AUTOLOAD, $EXTENSIONS, $TIEMAP);

our $VERSION   = '0.001';

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
		
	if (defined $JSON::JOM::Object::EXTENSIONS->{ $self->typeof }->{ $function })
	{
		my $coderef = $JSON::JOM::Object::EXTENSIONS->{ $self->typeof }->{ $function };
		if (ref $coderef eq 'CODE')
		{
			return $coderef->($self, @args);
		}
	}
	
	warn "Undefined method: $function";
	return undef;
}

sub DESTROY {}

sub can
{
	my ($self, $method) = @_;
	return 1
		if UNIVERSAL::can($self, $method);
	return 1
		if defined $JSON::JOM::Object::EXTENSIONS->{ $self->typeof }->{ $method }
		&& ref $JSON::JOM::Object::EXTENSIONS->{ $self->typeof }->{ $method } eq 'CODE';
	return;
}

sub new
{
	my ($class, $data, $meta) = @_;

	tie my %self, __PACKAGE__.'::Tie';
	my $self = bless \%self, $class;
	$TIEMAP->{ Scalar::Util::refaddr(tied(%self)) } = $self;
	
	$meta ||= {};
	while (my ($k,$v) = each %$meta)
	{
		$self->meta->{$k} = $v;
	}
	
	if ($self->meta->{rootNode} == 1)
	{
		$self->meta->{rootNode} = $self;
	}
	
	while (my ($k,$v) = each %$data)
	{
		$self{$k} = $v;
	}

	return $self;
}

sub meta
{
	my ($self) = @_;
	$META->{ Scalar::Util::refaddr($self) } ||= {};
	return $META->{ Scalar::Util::refaddr($self) };
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
	return 'HASH';
}

sub TO_JSON
{
	return { %{ $_[0] } };
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
	
	if ($self == $self->rootNode)
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

package JSON::JOM::Object::Tie;

use 5.008;
use Tie::Hash;
use base qw[Tie::StdHash];
use common::sense;

sub jsonobj
{
	my $tied = shift;
	return $JSON::JOM::Object::TIEMAP->{ Scalar::Util::refaddr($tied) };
}

sub sanitise
{
	my $value = $_[2];
	
	my $new;
	if (JSON::JOM::ref($value) eq 'ARRAY')
	{
		$new = JSON::JOM::Array->new([@$value]);
	}
	elsif (JSON::JOM::ref($value) eq 'HASH')
	{
		$new = JSON::JOM::Object->new({%$value});
	}
	
	if (defined $new)
	{
		my $old = jsonobj $_[0];
		$new->nodeIndex($_[1]);
		$new->parentNode($old);
		$new->rootNode($old->rootNode);
		$value = $new;
	}
	
	return $value;
}

sub TIEHASH
{
	my $storage = bless {}, shift;
	$storage
}

sub STORE
{
	$_[0]{$_[1]} = sanitise(@_);
}

1;


__END__

=head1 NAME

JSON::JOM::Object - represents an object in a JOM structure

=head1 DESCRIPTION

JOM objects have the following built-in methods. Other methods are
available in JOM plugins.

=over 4

=item * C<typeof> - returns the string 'HASH'.

=item * C<rootNode> - a reference to the root node of the JOM structure.

=item * C<isRootNode> - boolean; is this the root node of the JOM structure?

=item * C<parentNode> - a reference to the parent of this node in the JOM structure.

=item * C<nodePath> - a L<JSON::Path>-compatible string pointing to this node within the JOM structure.

=item * C<nodeIndex> - the array index or object key of the parentNode where this node is located.

=item * C<meta> - returns a hashref containing metadata about this node. This is intended for use by plugins.

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

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

