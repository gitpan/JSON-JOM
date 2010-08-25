use strict;
use warnings;

use inc::Module::Install;

my $dist = 'JSON-JOM';
my $fn   = "lib/$dist.pm"; $fn =~ s#-#/#g;

name                $dist;
perl_version_from   $fn;
version_from        $fn;
abstract_from       $fn;
readme_from         $fn;
author              'Toby Inkster <tobyink@cpan.org>';
license             'perl';

requires            'Carp'               => 0;
requires            'common::sense'      => 0;
requires            'Exporter'           => 0;
requires            'JSON'               => '2.00';
requires            'Module::Pluggable'  => 0;
requires            'Scalar::Util'       => 0;
test_requires       'Test::More'         => '0.61';
requires            'Tie::Array'         => 0;
requires            'Tie::Hash'          => 0;

resources(
	'homepage'   => "http://search.cpan.org/dist/$dist/",
	'repository' => "http://goddamn.co.uk/viewvc/perlmods/$dist/",
	'bugtracker' => "http://rt.cpan.org/Dist/Display.html?Queue=$dist",
	);
	
write_doap_changes;
write_doap_changes_xml;

include 'Test::Signature';
auto_install;
WriteAll(
	'meta' => 1,
	'sign' => 1,
	);
