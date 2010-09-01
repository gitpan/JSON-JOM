package JSON::JOM::Value;

use 5.008;
use base qw[JSON::JOM::Node];
use common::sense;
use overload bool => \&TO_JSON;
use overload '+0' => \&TO_JSON;
use overload '""' => \&TO_JSON;

use Carp;
use JSON qw[];
use Scalar::Util qw[];

our $VERSION   = '0.003';

sub new
{
	my ($class, $data, $meta) = @_;

	my $self = bless \$data, $class;
	
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
	return __PACKAGE__->new(JSON::true, {});
}

sub can
{
	return JSON::JOM::Object::can(@_);
}

sub typeof
{
	my $self = shift;
	return 'NULL'    unless defined $self->TO_JSON;
	return 'BOOLEAN' if JSON::is_bool( $self->TO_JSON );
	return 'NUMBER'  if Scalar::Util::looks_like_number( $self->TO_JSON );
	return 'STRING';
}

sub TO_JSON
{
	my $self = shift;
	return $$self;
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

Copyright 2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

