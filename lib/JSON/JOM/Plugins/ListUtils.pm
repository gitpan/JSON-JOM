package JSON::JOM::Plugins::ListUtils;

use 5.010;
use strict;
use utf8;
use Object::AUTHORITY;

BEGIN
{
	$JSON::JOM::Plugins::ListUtils::AUTHORITY = 'cpan:TOBYINK';
	$JSON::JOM::Plugins::ListUtils::VERSION   = '0.500';
}

sub extensions
{
	my ($class) = @_;
	return (
		['ARRAY', 'count',  sub { return scalar @{$_[0]}; }],
		['ARRAY', 'values', sub { return @{$_[0]}; }],
		['HASH',  'count',  sub { return scalar keys %{$_[0]}; }],
		['HASH',  'keys',   sub { return keys %{$_[0]}; }],
		['HASH',  'values', sub { return values %{$_[0]}; }],
		);
}

1;

__END__

=head1 NAME

JSON::JOM::Plugins::ListUtils - treat JOM nodes as lists

=head1 DESCRIPTION

This JOM plugin adds the following method to JOM objects and arrays:

=over 4

=item * C<count> - the length of the list.

=item * C<values> - all values as a Perl list.

=back

It adds the following method to JOM objects only:

=over 4

=item * C<keys> - all hash keys as a Perl list.

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<JSON::JOM>, L<JSON::JOM::Plugins>.

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

