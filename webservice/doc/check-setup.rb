#!/usr/bin/env ruby
#
# check-setup.rb
#
# Tests correct setup of webclient
#

###
# Helpers
#

def escape why, fix = nil, develop = nil
  $stderr.puts "*** Error: #{why}"
  $stderr.puts "Please #{fix}" if fix
  exit unless develop
end

def test what
  escape "(internal error) wrong use of 'test'" unless block_given?
  puts "Testing if #{what}"
  yield
end

def test_module name, package, develop = nil
  print "#{name} ... "
  begin
    require name
  rescue Exception => e
    escape "#{name} not available", "install #{package}", develop
  end
  puts "ok"
end

#
# test if package is installed
# return value
#  if package not installed: nil
#  else version string
#
def test_package package
  v = `rpm -q #{package}`
  return nil if v =~ /is not installed/
  nvr = v.split("-") # split name-version-release
  escape("can't extract version from #{v}", "check your installation") unless nvr.size > 2
  nvr.pop
  nvr.pop
end

#
# test if package is installed with minimum version
#
def test_version package, version
  ver = test_package package
  escape("#{package} not installed", "install #{package}") unless ver
  escape("#{package} not up-to-date", "upgrade to #{package}-#{version}") if ver < version
  true
end

def test_group name
  require 'etc'
  begin
    Etc.getgrnam name
  rescue ArgumentError
    escape "Group '#{name}' does not exist", "run 'groupadd -r #{name}' as root"
  end
end

def test_user name
  require 'etc'
  begin
    Etc.getpwnam name
  rescue ArgumentError
    escape "User '#{name}' does not exist", "run 'useradd  -g #{name} -s /bin/false -r -c \"User for WebYaST-Service\" -d /var/lib/#{name} #{name}' as root"
  end
end

###
# Tests
#

#
# runtime environment
#

test_module 'rubygems', 'rubygems'
test_module 'gettext', 'rubygem-gettext_rails'
test_module 'dbus', 'ruby-dbus'
test_package 'yast2-dbus-server'

test_module 'rpam', 'rubygem-rpam'
test_module 'polkit', 'rubygem-polkit'

test_group 'yastws'
test_user 'yastws'


#
# development environment
#

test_module 'mocha', 'rubygem-mocha', true
test_package 'rubygem-test-unit'
test_module 'rcov', 'rubygem-rcov'

puts "All fine, webservice is ready to run"
