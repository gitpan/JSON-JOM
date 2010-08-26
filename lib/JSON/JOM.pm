package JSON::JOM;

use 5.008;
use base qw[Exporter];
use common::sense;

use JSON qw[];
use JSON::JOM::Object;
use JSON::JOM::Array;

our $VERSION   = '0.002';
our @EXPORT    = qw[];
our @EXPORT_OK = qw[from_json to_json to_jom ref];
our %EXPORT_TAGS = (all => \@EXPORT_OK, standard => [qw[from_json to_json to_jom]], default => []);
our %PRAGMATA  = (
	'ref' => sub { *CORE::GLOBAL::ref = \&ref; },
	);

# provide overriden ref() function
sub ref ($)
{
	return 'ARRAY' if CORE::ref($_[0]) eq 'JSON::JOM::Array';
	return 'HASH'  if CORE::ref($_[0]) eq 'JSON::JOM::Object';
	return CORE::ref($_[0]);
}

# Totally stolen from Pragmatic on CPAN
# It's OK - licence allows.
sub import ($)
{
	my $argc    = scalar(@_);
	my $package = shift;

	my $warn = sub (;$) {
		require Carp;
		local $Carp::CarpLevel = 2; # relocate to calling package
		Carp::carp (@_);
	};

	my $die = sub (;$) {
		require Carp;
		local $Carp::CarpLevel = 2; # relocate to calling package
		Carp::croak (@_);
	};

	my @imports = grep /^[^-]/, @_;
	my @pragmata = map { substr($_, 1); } grep /^-/, @_;
	
	if ($argc==1 && !@imports && !@pragmata)
	{
		push @imports, ':default';
	}

	# Export first, for side-effects (e.g., importing globals, then
	# setting them with pragmata):
	$package->export_to_level (1, $package, @imports)
		if @imports;

	for (@pragmata)
	{
		no strict qw (refs);

		my ($pragma, $args) = split /=/, $_;
		my (@args) = split /,/, $args || '';

		exists ${"$package\::PRAGMATA"}{$pragma}
		or &$die ("No such pragma '$pragma'");

		if (ref ${"$package\::PRAGMATA"}{$pragma} eq 'CODE')
		{
			&{${"$package\::PRAGMATA"}{$pragma}} ($package, @args)
				or &$warn ("Pragma '$pragma' failed");
			# Let inheritance work for barewords:
		}
		elsif (my $ref = $package->can(${"$package\::PRAGMATA"}{$pragma}))
		{
			&$ref ($package, @args)
				or &$warn ("Pragma '$pragma' failed");
		}
		else
		{
			&$die ("Invalid pragma '$pragma'");
		}
	}
}

sub from_json ($;$)
{
	return to_jom(JSON::from_json($_[0], $_[1]||{}));
}

sub to_json ($;$)
{
	my %args = %{$_[1]};
	$args{convert_blessed} ||= 1;
	return JSON::to_json($_[0], \%args);
}

sub to_jom ($)
{
	my ($object) = @_;

	my $rv;
	
	if (JSON::JOM::ref($object) eq 'ARRAY')
	{
		$rv = JSON::JOM::Array->new($object,{rootNode=>1});
	}
	elsif (JSON::JOM::ref($object) eq 'HASH')
	{
		$rv = JSON::JOM::Object->new($object,{rootNode=>1});
	}
	
	return $rv if defined $rv;
	return $object;
}

1;

__END__

=head1 NAME

JSON::JOM - the JSON Object Model

=head1 SYNOPSIS

 # from_json and to_json compatible with the JSON module
 # but build JSON::JOM::Object and JSON::JOM::Array objects
 use JSON::JOM qw[from_json to_json]; 
 my $object = from_json('{ ...some json... }');
 
 # JOM objects are blessed hashrefs and arrayrefs
 # So you can read from them like this...
 my $thingy = $object->{'foo'}{'bar'}[0]{'quux'};
 
 # But look at this:
 my $array = $thingy->parentNode->parentNode;
 print $array->nodePath;  # $['foo']['bar']

=head1 DESCRIPTION

JSON::JOM provides a DOM-like API for working with JSON.

While L<JSON> represents JSON arrays as Perl arrayrefs and JSON objects as
Perl hashrefs, JSON::JOM represents each as a blessed object.

Internally, JSON::JOM::Object and JSON::JOM::Array store their data as a
hashref or arrayref, so you can still use this pattern of working:

  my $data = JSON::JOM::from_json(<<'JSON');
  {
    "foo": {
      "bar": [
        { "quux" : 0 },
        { "quux" : 1 },
        { "quux" : 2 },
      ]
    }
  }
  JSON
  
  foreach my $obj (@{ $data->{foo}{bar} })
  {
    printf("The quux of the matter is: %d\n", $obj->{quux})
  }

But all arrays and objects provide various methods to make working with
them a bit easier. See L<JSON::JOM::Object> and L<JSON::JOM::Array> for
descriptions of these methods.

Note that if you use the arrayref/hashref way of working, things are not
always intuitive:

  $root  = to_jom({});
  $child = [ 1,2,3 ];
  
  # Add $child to our JOM structure:
  $root->{list} = $child;
  
  print $root->{list}->count . "\n";  # prints '3'
  
  # Now modify $child
  push @$child, 4;
  
  print $root->{list}->count . "\n";  # still '3'!

This is because the C<$child> arrayref isn't just placed blindly into
the JOM structure, but "imported" into it. Compare the above with:

  $root  = to_jom({});
  $child = [ 1,2,3 ];
  
  # Add $child to our JOM structure, and this time,
  # set $child to point to the imported list.
  $child = $root->{list} = $child;
  
  print $root->{list}->count . "\n";  # prints '3'
  
  # Now modify $child
  push @$child, 4;
  
  print $root->{list}->count . "\n";  # prints '4'

=head1 FUNCTIONS

This modules provides the following functions. None of them are exported
by default.

  use JSON::JOM;              # export nothing
  use JSON::JOM ':standard';  # export first three
  use JSON::JOM ':all;        # export everything
  use JSON::JOM 'to_jom';     # export a particular function

=head2 C<< from_json($string, \%options) >>

JSON parser compatible with JSON::from_json.

=head2 C<< to_json($jom, \%options) >>

JSON serialiser compatible with JSON::from_json, except that
convert_blessed is always true.

=head2 C<< to_jom($data) >>

Converts a Perl hashref/arrayref structure to its JOM equivalent.

=head2 C<< JSON::JOM::ref($var) >>

Function compatible with the core function C<ref>, but
returns 'ARRAY' and 'HASH' for the JOM-equivalent structures.

The following will replace the core C<ref> with JSON::JOM::ref
globally.

  use JSON::JOM '-ref';

Expect the unexpected. C<CORE::ref> can still be called explicitly
if you genuinely want to detect the difference between a real
hashref/arrayref and a JSON::JOM::Object/Array.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

The real guts of JOM are in L<JSON::JOM::Object> and
L<JSON::JOM::Array>.

L<JSON::JOM::Plugins>.

L<JSON>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

