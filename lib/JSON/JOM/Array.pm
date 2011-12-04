package JSON::JOM::Array;

use 5.010;
use strict;
use utf8;
use Object::AUTHORITY;
use base qw[JSON::JOM::Object];
use UNIVERSAL::ref;
use Scalar::Util qw[];

BEGIN
{
	$JSON::JOM::Array::AUTHORITY = 'cpan:TOBYINK';
	$JSON::JOM::Array::VERSION   = '0.500';
}


sub new
{
	my ($class, $data, $meta) = @_;
	
	tie my @self, __PACKAGE__.'::Tie';
	my $self = bless \@self, $class;
	$JSON::JOM::Node::TIEMAP->{ Scalar::Util::refaddr(tied(@self)) } = $self;
	
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
	return JSON::JOM::Node::can(@_);
}

sub typeof
{
	return 'ARRAY';
}
*ref = \&typeof;

sub TO_JSON
{
	return [ @{ $_[0] } ];
}

sub toJSON
{
	my ($self, %opts) = @_;
	
	return '[]' unless @$self;
	
	$opts{indent_count}++;
	
	my $indent = ($opts{pretty}||$opts{indent}) ?
		(($opts{indent_character}||"\t") x ($opts{indent_count}||0)) :
		undef;
	my $linebreak = defined $indent ? "\n" : '';
	my $space_after = ($opts{pretty}||$opts{space_after}) ? ' ' : '';
	
	my $rv =
		join
			"${space_after},${linebreak}${indent}",
			map
				{ $_->toJSON(%opts) }
				@$self;

	$opts{indent_count}--;

	my $last_indent = ($opts{pretty}||$opts{indent}) ?
		(($opts{indent_character}||"\t") x ($opts{indent_count} || 0)) :
		undef;

	return "[${linebreak}${indent}${rv}${linebreak}${last_indent}]";
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

JSON::JOM::Array represents an array structure in JSON. It is a subclass of
JSON::JOM::Node.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<JSON::JOM>, L<JSON::JOM::Node>.

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

