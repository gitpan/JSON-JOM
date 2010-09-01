use Test::More tests => 9;
BEGIN { use_ok('JSON::JOM') };
BEGIN { use_ok('JSON::JOM::Plugins::ListUtils') };

my $obj = JSON::JOM::from_json('{"truth":true,"foo":1,"bar":[2,3,4]}');

is(JSON::JOM::to_json($obj, {canonical=>1}),
	'{"bar":[2,3,4],"foo":1,"truth":true}',
	'from_json and to_json work');
	
ok($obj->{'bar'}->can('count'),
	'plugins work');
	
is((join ',', sort $obj->{'bar'}->parentNode->keys),
	'bar,foo,truth',
	'paths work');

is($obj->{'truth'}->typeof,
	'BOOLEAN',
	'scalars seem ok - 1');

is($obj->{'truth'}.'',
	'true',
	'scalars seem ok - 2');

is($obj->{'truth'}->nodePath,
	"\$['truth']",
	'scalars seem ok - 3');

my $objxx = JSON::JOM::from_json('{"x":[1,[2,3],4]}');
is(join(',' ,$objxx->getDescendentsByType('NUMBER')),
	'1,2,3,4',
	'getDescendentsByType');
