package JSON::JOM::Plugins::Dumper;

use JSON qw[to_json];

our $VERSION   = '0.005';

sub extensions
{
	my ($class) = @_;
	return (
		['ARRAY', 'dump', sub { return to_json($_[0], {pretty=>1,convert_blessed=>1}) }],
		['HASH',  'dump', sub { return to_json($_[0], {pretty=>1,convert_blessed=>1}) }],
		);
}

1;

__END__

=head1 NAME

JSON::JOM::Plugins::Dumper - string dump for JOM nodes

=head1 DESCRIPTION

This JOM plugin adds the following method to JOM objects and arrays:

=over 4

=item * C<dump> - dumps the object as a JSON string.

=back

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

