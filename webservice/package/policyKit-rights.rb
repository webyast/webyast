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
   SuseString = "org.opensuse.yast"
   if action == "grant"
      # run "polkit-action" to list all registered policies
      IO.popen( "polkit-action", 'r+' ) do |pipe|
         loop do
            break if pipe.eof?
            l = pipe.read
	    # polkit-action prints one policy per line
            policies = l.split("\n")
	    # now 'blindly' grant org.opensuse.yast.*
            policies.each do |policy|
               if policy.include? SuseString and not policy.include? ".scr"
                  STDOUT.puts "granting: #{policy}"
                  command = "polkit-auth --user " + user + " --grant " + policy
                  unless system(command)
		    STDERR.puts "#{command} failed !"
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
                  STDOUT.puts l
               when "revoke"
                  policies = l.split("\n")
                  policies.each do |policy|
                    if policy.include? SuseString and not policy.include? ".scr"
                      STDOUT.puts "revoking: #{policy}"
                      command = "polkit-auth --user " + user + " --revoke " + policy
		      unless system(command)
			STDERR.puts "#{command} failed !"
		      end
                    end
                 end
            end
         end
      end
   end
end

