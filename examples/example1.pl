#!/usr/bin/perl

use 5.010;
use common::sense;
use lib "lib";

use Data::Dumper;
use JSON::JOM qw[:standard];
use Scalar::Util qw[blessed];

my $T = from_json('{"quux":[1,2,3,"foo\nbar",[1,2,3,true,false,null,[],{},false],{"abc":2,"xyzzy":1,"baz":"quux","foo":"bar"},null]}');
say $T->toJSON(pretty=>1,canonical=>1);
exit;

my $objxx = from_json('{"x":[1,[2,3],"4"]}');
print join(',' ,$objxx->getDescendentsByType('NUMBER'))."\n";

my $obj = from_json('{"a_bool":true,"foo":1,"bar":[{"quux":"2"},3,4]}');
$obj->{baz} = [7,8,9];
push @{ $obj->{baz} }, {'xyzzy'=>5};
unshift @{ $obj->{baz} }, {'xyzzy'=>1};
say ref $obj;
say blessed($obj); 
say to_json($obj,{'canonical'=>1});
say $obj->{'bar'}->can('count');
say $obj->{'baz'}[4]->nodePath;
say join ',', sort $obj->{'bar'}->parentNode->keys;
print $obj->to_yaml;

my $jom = to_jom([1,2,3,4,5,6,7,8,9]);
printf("Object has %d values.\n", $jom->count);
# print "$_\n" foreach $jom->values;

my $root  = to_jom({});
my $child = [ 1,2,3 ];

# Add $child to our JOM structure:
$root->{list} = $child;

print $root->{list}->count . "\n";  # prints '3'

# Now modify $child
push @$child, 4;

print $root->{list}->count . "\n";  # still '3'!

my $foo = $obj->{a_bool};

print $foo->typeof . " : $foo\n";

print $foo->parentNode->dump;