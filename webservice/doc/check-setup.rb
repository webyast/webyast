#!/usr/bin/env ruby
#
# check-setup.rb
#
# Tests correct setup of rest-service
#

###
# Helpers
#

def escape why, fix = nil
  $stderr.puts "*** Error: #{why}"
  $stderr.puts "Please #{fix}" if fix
  exit
end

def test what
  escape "(internal error) wrong use of 'test'" unless block_given?
  puts "Testing if #{what}"
  yield
end

def test_module name, package
  puts "Testing if #{package} is installed"
  begin
    require name
  rescue Exception => e
    escape "#{package} not installed", "install #{package}"
  end
end

def test_version package, need_version
  v = `rpm -q #{package}`
  escape v, "install #{package} >= #{need_version}" if v =~ /is not installed/
  nvr = v.chomp.split "-"
  have_release = nvr.pop
  have_version = nvr.pop
  escape "#{package} not up-to-date", "upgrade to #{package}-#{need_version}"  if have_version < need_version
  true
end

###
# Tests
#

#
# rpam
#
test_module "rpam", "ruby-rpam"


#
# ruby-polkit
#
test_module "polkit", "ruby-polkit"


#
# /etc/yast_user_roles
#
test "User roles configured" do
  unless File.exists? "/etc/yast_user_roles"
    escape "/etc/yast_user_roles does not exist", "create /etc/yast_user_roles"
  end
end

#
# ruby-dbus
#

test_module "dbus", "ruby-dbus"

#
# yast-dbus, scr
#

test "YaST D-Bus service available" do
  begin
    require "dbus"
    bus = DBus::SystemBus.instance
  rescue Exception => e
  end
  escape "System error, cannot access D-Bus SystemBus" unless bus
  
  begin
    proxy = bus.introspect( "org.opensuse.yast.SCR", "/SCR" )
  rescue Exception => e
  end
  
  os_version = nil
  # check if we're on openSUSE 11.2, this has yast2-dbus-service splitted from yast2-core
  File.open("/etc/SuSE-release") do |fd|
    fd.each do |line|
      next unless line =~ /^VERSION = (.*)/
      os_version = $1 
    end 
  end rescue nil

  if os_version == "11.2"
    package = "yast2-dbus-server"
    version = "2.18.0"
  else
    package = "yast2-core"
    version = "2.18.10"
  end
  
  unless proxy
    $stderr.puts "YaST D-Bus service not available"
    unless test_version package, version
      escape "#{package} not correctly installed", "reinstall #{package}-#{version}"
    end
    exit
  end

  begin
    scr = proxy["org.opensuse.yast.SCR.Methods"]
  rescue Exception => e
    $stderr.puts "scr failed: #{e}"
  end
  escape "YaST D-Bus does not provide the right data", "reinstall #{package}-#{version}" unless scr
end


puts "All fine, rest-service is ready to run"

