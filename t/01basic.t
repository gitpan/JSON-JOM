use Test::More tests => 5;
BEGIN { use_ok('JSON::JOM') };
BEGIN { use_ok('JSON::JOM::Plugins::ListUtils') };

my $obj = JSON::JOM::from_json('{"foo":1,"bar":[2,3,4]}');

is(JSON::JOM::to_json($obj, {canonical=>1}),
	'{"bar":[2,3,4],"foo":1}',
	'from_json and to_json work');
	
ok($obj->{'bar'}->can('count'),
	'plugins work');
	
is((join ',', sort $obj->{'bar'}->parentNode->keys),
	'bar,foo',
	'paths work');
