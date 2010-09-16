use Test::More tests => 4;

use JSON::JOM;

my $struct = JSON::JOM::from_json('{"array":[1]}');

is(ref $struct,
	'HASH',
	'ref HASH works');

is(ref $struct->{array},
	'ARRAY',
	'ref ARRAY works');

ok(!ref $struct->{array}[0],
	'ref VALUE works');

$_ = $struct;

is(ref,
	'HASH',
	'ref $_ works');
