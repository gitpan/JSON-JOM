package JSON::JOM::Plugins::TreeUtils;

use JSON::JOM::Plugins::ListUtils;

our $VERSION   = '0.004';

sub extensions
{
	my ($class) = @_;
	return (
		['NODE',  'hasAncestor',          \&_hasAncestor],
		['ARRAY', 'hasDescendent',        \&_hasDescendent],
		['ARRAY', 'hasChild',             \&_hasChild],
		['ARRAY', 'getChildrenByType',    \&_getChildrenByType],
		['ARRAY', 'getDescendentsByType', \&_getDescendentsByType],
		['HASH',  'hasDescendent',        \&_hasDescendent],
		['HASH',  'hasChild',             \&_hasChild],
		['HASH',  'getChildrenByType',    \&_getChildrenByType],
		['HASH',  'getDescendentsByType', \&_getDescendentsByType],
		);
}

sub _hasDescendent
{
	my ($possibleAncestor, $possibleDescendent) = @_;
	
	return
		if $possibleDescendent->isRootNode;
	
	return
		if $possibleAncestor->id eq $possibleDescendent->id;
	
	return 1
		if _hasChild($possibleAncestor, $possibleDescendent);

	return _hasDescendent($possibleAncestor, $possibleDescendent->parentNode);
}

sub _hasChild
{
	my ($possibleAncestor, $possibleDescendent) = @_;
	
	return 1
		if !$possibleDescendent->isRootNode
		&& defined $possibleDescendent->parentNode
		&& $possibleDescendent->parentNode->id eq $possibleAncestor->id;
	return;
}

sub _hasAncestor
{
	my ($x, $y) = @_;
	return _hasDescendent($y, $x);
}

sub _getChildrenByType
{
	my ($self, $type) = @_;
	
	my @values = $self->values;
	
	if (uc $type eq 'NODE' or $type eq '*')
	{
		return @values;
	}
	
	return grep { uc $type eq uc $_->typeof } @values;
}

sub _getDescendentsByType
{
	my ($self, $type) = @_;
	
	my @rv;
	foreach my $kid ($self->values)
	{
		if (uc $type eq 'NODE'
		or  $type eq '*'
		or  uc $type eq uc $kid->typeof)
		{
			push @rv, $kid;
		}
		if ($kid->typeof eq 'ARRAY'
		or  $kid->typeof eq 'HASH')
		{
			push @rv, _getDescendentsByType($kid, $type);
		}
	}
	
	return @rv;
}

1;

__END__

=head1 NAME

JSON::JOM::Plugins::TreeUtils - add tree methods

=head1 DESCRIPTION

This JOM plugin adds the following method to JOM objects and arrays:

=over 4

=item * C<< hasDescendent($x) >> - returns true if $x is a descendent of the current node.

=item * C<< hasChild($x) >> - returns true if $x is a direct child of the current node. This should be faster than looping through C<values>.

=item * C<< getDescendentsByType($type) >> - list of descendent nodes where C<typeof> is $type. $type may be '*'. Returns results in depth-first order.

=item * C<< getChildrenByType($type) >> - list of child nodes where C<typeof> is $type. $type may be '*'.

=back

It adds the following method to all JOM nodes:

=over 4

=item * C<< hasAncestor($x) >> - returns true if $x is an ancestor of the current node.

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

