#!/usr/bin/env ruby
#--
# Webyast Webservice framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

#
# check-setup.rb
#
# Tests correct setup of webclient
#

$production_errors = 0
$development_errors = 0

###
# Helpers
#

def escape severity, why, fix = nil
  $stderr.puts "*** %s error: %s" % [ severity.to_s.capitalize, why ]
  $stderr.puts "\tPlease #{fix}" if fix
  case severity
    when :production: $production_errors += 1
    when :development: $development_errors += 1
    when :generic: exit
  end
end

def test what
  escape "(internal error) wrong use of 'test'" unless block_given?
  puts "Testing if #{what}"
  yield
end

def test_module severity, name, package
  print "#{name} ... "
  begin
    require name
  rescue Exception => e
    puts "no"
    escape severity, "#{name} not available", "install #{package}"
  else
    puts "ok"
  end
end

#
# test if package is installed
# return value
#  if package not installed: nil
#  else version string
#
def test_package severity, package
  v = `rpm -q #{package}` # RORSCAN_ITL
  return nil if v =~ /is not installed/
  nvr = v.split("-") # split name-version-release
  escape(severity, "can't extract version from #{v}", "check your installation") unless nvr.size > 2
  nvr.pop
  nvr.pop
end

#
# test if package is installed with minimum version
#
def test_version severity, package, version = nil
  ver = test_package severity, package
  escape(severity, "#{package} not installed", "install #{package}") unless ver
  escape(severity, "#{package} not up-to-date", "upgrade to #{package}-#{version}") if version && ver < version
  true
end

def test_group severity, name
  require 'etc'
  begin
    Etc.getgrnam name
  rescue ArgumentError
    escape severity, "Group '#{name}' does not exist", "run 'groupadd -r #{name}' as root"
  end
end

def test_user severity, name
  require 'etc'
  begin
    Etc.getpwnam name
  rescue ArgumentError
    escape severity, "User '#{name}' does not exist", "run 'useradd  -g #{name} -s /bin/false -r -c \"User for WebYaST-Service\" -d /var/lib/#{name} #{name}' as root"
  end
end

def test_policy policy, user
end

###
# Tests
#

#
# runtime environment
#

test_module :generic, 'rubygems', 'rubygems'
test_module :generic, 'gettext', 'rubygem-gettext_rails'
test_module :generic, 'dbus', 'ruby-dbus'
test_version :generic, 'sqlite3'
test_module :generic, 'sqlite3', 'rubygem-sqlite3'
test_version :generic, 'yast2-dbus-server'

test_module :generic, 'rpam', 'rubygem-rpam'
test_module :generic, 'polkit', 'rubygem-polkit'

test_group :production, 'yastws'
test_user :production, 'yastws'


#
# development environment
#

# Doesn't work, test/unit throws error:
# test_module :development, 'test/unit', 'rubygem-test-unit'

test_version :development, 'rubygem-test-unit'
test_module :development, 'mocha', 'rubygem-mocha'
test_version :development, 'rubygem-test-unit'
test_module :development, 'rcov', 'rubygem-rcov'
test_module :development, 'nokogiri', 'rubygem-nokogiri'
test_module :development, 'tidy', 'rubygem-tidy'
test_version :development, 'tidy'

test_policy "org.opensuse.yast.system.status.read", Etc.getlogin

# reqd for Users mgmt
test_policy "org.opensuse.yast.modules.yapi.users.groupsget", Etc.getlogin

puts "Cannot run in production" if $production_errors > 0
puts "Cannot run in development" if $development_errors > 0
  
puts "All fine, webservice is ready to run" if $production_errors + $development_errors == 0
