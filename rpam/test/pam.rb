#!/usr/bin/ruby

# load the local copy, not the installed rpam.so
$:.unshift("../ext/Rpam")

require "rpam"
include Rpam

user = "root"
password = "password"

begin
  res = authpam(user,password)
  if res
    puts "Authenticate Successful"
  else
    puts "Authenticate Failure"
  end
rescue
  $stderr.puts "Please edit pam.rb and choose a different user name"
  exit
end
