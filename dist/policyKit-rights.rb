#!/usr/bin/ruby
#
# policyKit-rights.rb
#
# show, grant and revoke policies for YaST webservice
#
# run: ruby policyKit-rights.rb
#
#
require 'fileutils'
require 'getoptlong'

$debug = 0

def usage why
	STDERR.puts why
	STDERR.puts "Usage: policyKit-rights.rb --user <user> --action (show|grant|revoke)"
        STDERR.puts "NOTE: This program should be run by user root"
        STDERR.puts ""
        STDERR.puts "This call grant/revoke ALL permissions for the YaST Webservice."
        STDERR.puts "In order to grant/revoke single rights use:"
        STDERR.puts "polkit-auth --user <user> (--grant|-revoke) <policyname>"
        STDERR.puts ""
        STDERR.puts "In order to show all possible permissions use:"
        STDERR.puts "polkit-action"
	exit 1
end

options = GetoptLong.new(
  [ "--user",   GetoptLong::REQUIRED_ARGUMENT ],
  [ "--action", GetoptLong::REQUIRED_ARGUMENT ]
)

user = nil
action = nil


begin
options.each do |opt, arg|
  case opt
    when "--user": user = arg
    when "--action": action = arg
    when "--debug": $debug += 1
    else
	STDERR.puts "Ignoring unrecognized option #{opt}"
  end
end
rescue
end

$debug = nil if $debug == 0

usage "excessive arguments" unless ARGV.empty?
usage "--user parameter missing" unless user
usage "--action parameter (show|grant|revoke) missing" unless action

begin
   if action == "grant"
      IO.popen( "polkit-action", 'r+' ) do |pipe|
         loop do
            suseString = "org.opensuse.yast."
            break if pipe.eof?
            l = pipe.read
            policies = l.split("\n")
            policies.each do |policy|
               if policy.include? suseString
                  policySplit = policy.split("-")
                  if policySplit.size >= 2 
                     command = "polkit-auth --user " + user + " --explicit |grep -s " + policySplit[0] + "-" + policySplit[1] + " >>/dev/null"
                     if ( !system(command) or # has not already been set
                          policy == "org.opensuse.yast.webservice.read-userlist" or  #special cases
                          policy == "org.opensuse.yast.webservice.read-user" )
                       STDERR.puts "granting: #{policy}"
                       command = "polkit-auth --user " + user + " --grant " + policySplit[0] + "-" + policySplit[1]
                       system (command)
                     end
                  elsif policySplit.size == 1 #only root available
                       STDERR.puts "granting: #{policy}"
                       command = "polkit-auth --user " + user + " --grant " + policy
                       system (command)
                  end
               end
            end
         end
      end
   else
      command = "polkit-auth --user " + user + " --explicit"
      IO.popen( command, 'r+' ) do |pipe|
         loop do
            break if pipe.eof?
            l = pipe.read
            case action
               when "show"
                  STDERR.puts l
               when "revoke"
                  policies = l.split("\n")
                  policies.each do |policy|
                    STDERR.puts "revoking: #{policy}"
                    command = "polkit-auth --user " + user + " --revoke " + policy
                    system (command)
                 end
            end
         end
      end
   end
end

