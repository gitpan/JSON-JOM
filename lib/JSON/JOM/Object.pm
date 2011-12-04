package JSON::JOM::Object;

use 5.010;
use strict;
use utf8;
use Object::AUTHORITY;

use base qw[JSON::JOM::Node];
use UNIVERSAL::ref;

use Scalar::Util qw[];

BEGIN
{
	$JSON::JOM::Object::AUTHORITY = 'cpan:TOBYINK';
	$JSON::JOM::Object::VERSION   = '0.500';
}

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
*ref = \&typeof;

sub TO_JSON
{
	return { %{ $_[0] } };
}

sub toJSON
{
	my ($self, %opts) = @_;
	
	return '{}' unless %$self;
	
	$opts{indent_count}++;
	
	my $indent = ($opts{pretty}||$opts{indent}) ?
		(($opts{indent_character}||"\t") x ($opts{indent_count}||0)) :
		undef;
	my $linebreak = defined $indent ? "\n" : '';
	my $space_after  = ($opts{pretty}||$opts{space_after})  ? ' ' : '';
	my $space_before = ($opts{pretty}||$opts{space_before}) ? ' ' : '';
	
	my @keys = $opts{canonical} ?
		(sort keys %$self) :
		(keys %$self);
	
	my $rv =
		join
			"${space_after},${linebreak}${indent}",
			map
				{ sprintf("%s${space_before}:${space_after}%s", JSON::JOM::_string_to_json($_, %opts), $self->{$_}->toJSON(%opts)) }
				@keys;

	$opts{indent_count}--;

	my $last_indent = ($opts{pretty}||$opts{indent}) ?
		(($opts{indent_character}||"\t") x ($opts{indent_count} || 0)) :
		undef;

	return "{${linebreak}${indent}${rv}${linebreak}${last_indent}}";
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

Copyright 2010-2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

