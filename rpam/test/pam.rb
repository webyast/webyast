#!/usr/bin/ruby

  require "rpam"
  include Rpam

  if authpam("username","password") == true
	puts "Authenticate Successful"
  else
  	puts "Authenticate Failure"
  end
