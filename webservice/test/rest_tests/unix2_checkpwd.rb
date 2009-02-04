#!/usr/bin/ruby
require 'rubygems'
require 'session'

puts "Starting /sbin/unix2_chkpwd"

cmd = "/sbin/unix2_chkpwd rpam root"
text = "llllll"

se = Session.new
result, err = se.execute cmd, :stdin => text

puts result
puts err
puts se.get_status

puts "End /sbin/unix2_chkpwd"