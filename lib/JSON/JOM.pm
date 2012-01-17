package JSON::JOM;

use 5.010;
use base qw[Exporter];
use strict;
use utf8;

use JSON qw[];
use Scalar::Util qw[];
use Object::AUTHORITY;

use JSON::JOM::Node;
use JSON::JOM::Object;
use JSON::JOM::Array;
use JSON::JOM::Value;

our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);

BEGIN
{
	$JSON::JOM::AUTHORITY = 'cpan:TOBYINK';
	$JSON::JOM::VERSION   = '0.501';

	@EXPORT    = qw[];
	@EXPORT_OK = qw[from_json to_json to_jom ref];
	%EXPORT_TAGS = (
		all      => \@EXPORT_OK,
		standard => [qw/from_json to_json to_jom/],
		default  => \@EXPORT,
		);
}
	
sub ref ($)
{
	if (Scalar::Util::blessed($_[0]) =~ /^JSON::JOM::(Node|Object|Array|Value)$/
	&&  $_[0]->can('ref'))
	{
		return $_[0]->ref;
	}
	return ref($_[0]);
}

sub from_json ($;$)
{
	return to_jom(JSON::from_json($_[0], $_[1]||{}));
}

sub to_json ($;$)
{
	return $_[0]->toJSON(%{$_[1]});
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

{
	my %esc = (
		"\n" => '\n',
		"\r" => '\r',
		"\t" => '\t',
		"\f" => '\f',
		"\b" => '\b',
		"\"" => '\"',
		"\\" => '\\\\',
		"\'" => '\\\'',
		);

	sub _JSON_PP_encode_ascii {
		 join('',
			  map {
					$_ <= 127 ?
						 chr($_) :
					$_ <= 65535 ?
						 sprintf('\u%04x', $_) : sprintf('\u%x\u%x', _encode_surrogates($_));
			  } unpack('U*', $_[0])
		 );
	}

	sub _JSON_PP_encode_latin1 {
		 join('',
			  map {
					$_ <= 255 ?
						 chr($_) :
					$_ <= 65535 ?
						 sprintf('\u%04x', $_) : sprintf('\u%x\u%x', _encode_surrogates($_));
			  } unpack('U*', $_[0])
		 );
	}

	sub _encode_surrogates { # from perlunicode
		 my $uni = $_[0] - 0x10000;
		 return ($uni / 0x400 + 0xD800, $uni % 0x400 + 0xDC00);
	}

	sub _string_to_json
	{
		my ($arg, %opts) = @_;

		$arg =~ s/([\x22\x5c\n\r\t\f\b])/$esc{$1}/g;
		$arg =~ s/\//\\\//g;
		$arg =~ s/([\x00-\x08\x0b\x0e-\x1f])/'\\u00' . unpack('H2', $1)/eg;

		if ($opts{ascii})
		{
			$arg = _JSON_PP_encode_ascii($arg);
		}

		if ($opts{latin1})
		{
			$arg = _JSON_PP_encode_latin1($arg);
		}

		if ($opts{utf8})
		{
			utf8::encode($arg);
		}

		return '"' . $arg . '"';
	}
};

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

Values that the JSON module would represent as a Perl scalar, are
represented as a JSON::JOM::Value in JOM. This uses L<overload> to
act like a scalar.

Note that if you use the arrayref/hashref way of working, things
are not always completely intuitive:

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

JSON serialiser mostly compatible with JSON::to_json.

=head2 C<< to_jom($data) >>

Converts a Perl hashref/arrayref structure to its JOM equivalent.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

The real guts of JOM are in L<JSON::JOM::Object>,
L<JSON::JOM::Array> and L<JSON::JOM::Value>.

L<JSON::JOM::Plugins>.

L<JSON>.

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

