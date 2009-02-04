#!/usr/bin/ruby

# load the local copy, not the installed rpam.so
$:.unshift("../ext/Rpam")

require "rpam"
include Rpam

res = authpam("root","novell")
if res
  puts "Authenticate Successful"
else
  puts "Authenticate Failure"
end

exit res
