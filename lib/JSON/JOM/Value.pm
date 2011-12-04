package JSON::JOM::Value;

use 5.010;
use strict;
use utf8;
use Object::AUTHORITY;

use base qw[JSON::JOM::Node];
use overload bool => \&TO_JSON;
use overload '0+' => \&TO_JSON;
use overload '""' => \&TO_JSON;
use overload 'cmp' => sub { my ($a,$b) = @_; return "$a" cmp "$b"; };
use overload '<=>' => sub { my ($a,$b) = @_; return (0+$a) <=> (0+$b); };
use UNIVERSAL::ref;

use B qw[];
use JSON qw[];

BEGIN
{
	$JSON::JOM::Value::AUTHORITY = 'cpan:TOBYINK';
	$JSON::JOM::Value::VERSION   = '0.500';
}

sub new
{
	my ($class, $data, $meta) = @_;

	my $self = bless \$data, $class;
	
	$self->meta->{typeof} = do
	{ 
		my $b_obj = B::svref_2object(\$data);
		my $flags = $b_obj->FLAGS;

		if (!defined $data)                            { 'NULL' ; }
		elsif (JSON::is_bool($data))                   { 'BOOLEAN' ; }
		elsif (
				(
					$flags & B::SVf_IOK or
					$flags & B::SVp_IOK or
					$flags & B::SVf_NOK or
					$flags & B::SVp_NOK
				)
				and !($flags & B::SVf_POK)
			)                                           { 'NUMBER' ; }
		else                                           { 'STRING' ; }
	};
	
	$meta ||= {};
	while (my ($k,$v) = each %$meta)
	{
		$self->meta->{$k} = $v;
	}

	return $self;
}

sub TRUE
{
	return __PACKAGE__->new(JSON::true, {});
}

sub FALSE
{
	return __PACKAGE__->new(JSON::false, {});
}

sub NULL
{
	return __PACKAGE__->new(undef, {});
}

sub can
{
	return JSON::JOM::Object::can(@_);
}

sub typeof
{
	my $self = shift;
	return uc $self->meta->{typeof};
}

sub ref
{
	return;
}

sub TO_JSON
{
	my $self = shift;
	my $rv   = $$self;
	
	if ($self->typeof eq 'NULL')
	{
		return undef;
	}
	elsif ($self->typeof eq 'BOOLEAN')
	{
		return $rv ? JSON::true : JSON::false;
	}
	elsif ($self->typeof eq 'NUMBER')
	{
		return 0 + $rv;
	}
	else
	{
		return "$rv";
	}
}

sub toJSON
{
	my ($self, %opts) = @_;
	my $rv   = $$self;

	if ($self->typeof eq 'NULL')
	{
		return 'null';
	}
	elsif ($self->typeof eq 'BOOLEAN')
	{
		return $rv ? 'true' : 'false';
	}
	elsif ($self->typeof eq 'NUMBER')
	{
		return 0 + $rv;
	}
	else
	{
		return JSON::JOM::_string_to_json("$rv", %opts);
	}
}

sub isRootNode
{
	return;
}

1;


__END__

=head1 NAME

JSON::JOM::Value - represents a value in a JOM structure

=head1 DESCRIPTION

JSON::JOM::Value represents a simple value (null, boolean, number or string)
in JSON. It is a subclass of JSON::JOM::Node.

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

