package JSON::JOM::Array;

use 5.008;
use base qw[JSON::JOM::Object];
use common::sense;

use Scalar::Util qw[];

our $VERSION   = '0.001';

sub new
{
	my ($class, $data, $meta) = @_;
	
	tie my @self, __PACKAGE__.'::Tie';
	my $self = bless \@self, $class;
	$JSON::JOM::Object::TIEMAP->{ Scalar::Util::refaddr(tied(@self)) } = $self;
	
	$meta ||= {};
	while (my ($k,$v) = each %$meta)
	{
		$self->meta->{$k} = $v;
	}
	
	if ($self->meta->{rootNode} == 1)
	{
		$self->meta->{rootNode} = $self;
	}
	
	for(my $i=0; $i < scalar @$data; $i++)
	{
		$self[$i] = $data->[$i];
	}
	
	return $self;
}

sub can
{
	return JSON::JOM::Object::can(@_);
}

sub typeof
{
	return 'ARRAY';
}

sub TO_JSON
{
	return [ @{ $_[0] } ];
}

1;

package JSON::JOM::Array::Tie;

use 5.008;
use common::sense;
use Tie::Array;
use base qw[Tie::StdArray];

use Scalar::Util qw[];

sub TIEARRAY
{
	my $storage = bless [], shift;
	$storage;
}

sub STORE
{
	$_[0][$_[1]] = JSON::JOM::Object::Tie::sanitise(@_);
}

sub PUSH
{
	my $this = shift;
	my $i = scalar @$this;
	foreach (@_)
	{
		push @$this, JSON::JOM::Object::Tie::sanitise($this, $i, $_);
		$i++;
	}
}

sub UNSHIFT
{
	my $this = shift;
	foreach (@_)
	{
		unshift @$this, JSON::JOM::Object::Tie::sanitise($this, 0, $_);
	}
	for (my $i=0; $i < scalar @$this; $i++)
	{
		if (Scalar::Util::blessed($this->[$i]) && $this->[$i]->can('nodeIndex'))
		{
			$this->[$i]->nodeIndex($i);
		}
	}
}

sub SPLICE
{
	my $ob  = shift;
	my $sz  = $ob->FETCHSIZE;
	my $off = @_ ? shift : 0;
	$off   += $sz if $off < 0;
	my $len = @_ ? shift : $sz-$off;
	my @rv = splice(@$ob,$off,$len,@_);
	
	for (my $i=0; $i < scalar @$ob; $i++)
	{
		if (Scalar::Util::blessed($ob->[$i]) && $ob->[$i]->can('nodeIndex'))
		{
			$ob->[$i]->nodeIndex($i);
		}
	}
	
	return @rv;
}

sub SHIFT
{
	my $this = shift;
	my $x = shift @$this;

	for (my $i=0; $i < scalar @$this; $i++)
	{
		if (Scalar::Util::blessed($this->[$i]) && $this->[$i]->can('nodeIndex'))
		{
			$this->[$i]->nodeIndex($i);
		}
	}
	
	return $x;
}

1;

__END__

=head1 NAME

JSON::JOM::Array - represents an array in a JOM structure

=head1 DESCRIPTION

JOM arrays have the following built-in methods. Other methods are
available in JOM plugins.

=over 4

=item * C<typeof> - returns the string 'ARRAY'.

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

