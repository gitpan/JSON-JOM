package JSON::JOM::Object;

use 5.008;
use base qw[JSON::JOM::Node];
use common::sense;

use Scalar::Util qw[];

our $VERSION   = '0.003';

sub new
{
	my ($class, $data, $meta) = @_;

	tie my %self, __PACKAGE__.'::Tie';
	my $self = bless \%self, $class;
	$JSON::JOM::Node::TIEMAP->{ Scalar::Util::refaddr(tied(%self)) } = $self;
	
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

sub can
{
	return JSON::JOM::Node::can(@_);
}

sub typeof
{
	return 'HASH';
}

sub TO_JSON
{
	return { %{ $_[0] } };
}

1;

package JSON::JOM::Object::Tie;

use 5.008;
use Tie::Hash;
use base qw[Tie::StdHash];
use common::sense;

use Scalar::Util qw[];

sub jsonobj
{
	my $tied = shift;
	return $JSON::JOM::Node::TIEMAP->{ Scalar::Util::refaddr($tied) };
}

sub sanitise
{
	my $value = $_[2];
	
	my $old = jsonobj $_[0];
	my $opts = {
		nodeIndex  => $_[1],
		parentNode => $old,
		rootNode   => $old->rootNode,
		};
	if (JSON::JOM::ref($value) eq 'ARRAY')
	{
		return JSON::JOM::Array->new([@$value], $opts);
	}
	elsif (JSON::JOM::ref($value) eq 'HASH')
	{
		return JSON::JOM::Object->new({%$value}, $opts);
	}
	elsif (JSON::is_bool($value))
	{
		return JSON::JOM::Value->new($value, $opts);
	}
	elsif (!JSON::JOM::ref($value))
	{
		return JSON::JOM::Value->new($value, $opts);
	}
	
	return $value;
}

sub TIEHASH
{
	my $storage = bless {}, shift;
	$storage;
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

JSON::JOM::Object represents an object structure (a.k.a. 'dictionary', 'hash',
or 'associative array') in JSON. It is a subclass of JSON::JOM::Node.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<JSON::JOM>, L<JSON::JOM::Node>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

