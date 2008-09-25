#!/usr/bin/ruby

  require "rpam"
  include Rpam

  if authpam("tuxtux","tuxtux") == true
	puts "Authenticate Successful"
  else
  	puts "Authenticate Failure"
  end
