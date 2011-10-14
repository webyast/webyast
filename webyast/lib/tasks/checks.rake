#--
# Webyast framework
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

require 'rubygems'
require 'polkit1'

###
# Helpers
#

class Error
  @@errors = 0
  def self.inc
    @@errors += 1
  end
  def self.errors
    @@errors
  end
end

def escape why, fix = nil
  $stderr.puts "*** ERROR: #{why}"
  $stderr.puts "Please #{fix}" if fix
  exit(1) unless ENV["SYSTEM_CHECK_NON_STRICT"]
  Error.inc
end

def warn why, fix = nil
  $stderr.puts "*** WARNING: #{why}"
  $stderr.puts "Please #{fix}" if fix
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

def test_version package, version = nil
  puts "Testing if #{package} #{version} is installed"
  old_lang = ENV['LANG']
  ENV['LANG'] = 'C'
  v = `rpm -q --whatprovides #{package}`
  ENV['LANG'] = old_lang
  if v =~ /is not installed/ || v =~ /no package provides/
    escape v, "install #{package} >= #{version}" if version
    escape v, "install #{package}"
  end
  return if version.blank? # just check package, not version
  nvr = v.split "-"
  rel = nvr.pop
  ver = nvr.pop
  ENV['LANG'] = 'C'
  v = `zypper vcmp #{ver} #{version}`
  ENV['LANG'] = old_lang
  if v =~ /is older/
    escape "#{package} not up-to-date (installed:#{ver}) upgrade to #{package}-#{version}"
  end
end

###
# Tests
#

desc "Check that your build environment is set up correctly for WebYaST"
task :system_check do
  
  #
  # check needed packages which have been defined in the spec files
  #
  packages = {} #key: packagename ; value:version
  `find . -name "*.spec"`.each_line { |spec_file|
    `egrep "Req:|Requires:" #{spec_file}`.each_line { |require|
      unless require.lstrip.start_with?("#")
        require.delete!(",")
        package_list = require.split
	package_list.shift #rmove PreReq:,Requires:,...
        i = 0
	while i <= package_list.size-1
	  unless package_list[i].strip.start_with?("webyast")
	    if i+2<package_list.size && package_list[i+1].start_with?(">")
	      packages[package_list[i]] = package_list[i+2] 
	      i += 3
	    else
	      unless package_list[i].start_with?("%{name}") ||
	      	     package_list[i].start_with?("%{version}") ||
		     package_list[i].start_with?("=") ||
                     package_list[i].start_with?("<")
    	        packages[package_list[i]] = "" unless packages.has_key?(package_list[i])
              end
    	      i += 1
	    end
	  else
   	    i += 1
	  end
	end
      end
    }    
  }

  packages.each { |package,version|
    test_version package, version
  }

  # check that policies are all installed
  not_needed = ['org.opensuse.yast.scr.policy']
  policy_files = File.expand_path(File.join(File.dirname(__FILE__), '../../..', "**/*.policy"))
  Dir.glob(policy_files) do |fname|
    policy = File.basename(fname)
    next if not_needed.include?(policy)
    plugin = if fname =~ %r{plugins/([^/]*)}
               $1
	     else
	       File.dirname fname
	     end
    dest_policy = File.join('/usr/share/polkit-1/actions', policy)
    if not File.exists?(dest_policy)
      escape "Policy '#{policy}' of plugin '#{plugin}' is not installed",
             "Run \"sudo rake install_policies\" in plugin '#{plugin}'\n or run\nsudo cp #{fname} #{dest_policy}"
    end
  end

  user = ENV['USER']

  # check that the user running the web service has permissions to yast
  # and others like packagekit. This can be achieved by:
  # manually "grantwebyastrights --user <user> --action grant --policy <policy>

  webyast_actions = [ 'org.freedesktop.packagekit.system-update', 'org.freedesktop.packagekit.package-install',  'org.opensuse.yast.module-manager.import', 
                      'org.freedesktop.hal.power-management.shutdown', 'org.freedesktop.hal.power-management.shutdown-multiple-sessions',
                      'org.freedesktop.hal.power-management.reboot', 'org.freedesktop.hal.power-management.reboot-multiple-sessions',
                      'org.freedesktop.packagekit.system-sources-configure', 'org.freedesktop.packagekit.package-eula-accept']

  webyast_actions.each do | action|
    unless PolKit1::polkit1_check(action, user) == :yes
      escape "policy #{action} is not granted and it is needed to run webyast as #{user}.", "Run 'grantwebyastrights --user #{user} --action grant --policy #{action}' to grant the permission.\n"
    end
  end

  #
  # yast-dbus
  #

  test "YaST D-Bus service available" do
    begin
      require "dbus"
      bus = DBus::SystemBus.instance
    rescue Exception => e
    end
    escape "System error, cannot access D-Bus SystemBus" unless bus

    package = "yast2-dbus-server"
#    version = (os_version == "11.2")?"2.18.1":"2.17.0"
#    test_version package, version
  end

  #
  # plugin-specific tests
  #
  
  # mailsettings
  test "Mail YaPI existance" do
    unless File.exists? "/usr/share/YaST2/modules/YaPI/MailSettings.pm"
      warn "mail_settings incomplete", "Install /usr/share/YaST2/modules/YaPI/MailSettings.pm from plugins/mail_settings"
    end
  end

  test_version "yast2-mail"
#  test_version "yast2", (os_version == "11.2")?"2.18.24":"2.17.72"

  #
  # plugin test. Each plugin will be tested for a "GET show" call OR a "GET index" call. This call should return success.
  # If not an warning will be reported only.
  #

  test "all available plugins are working" do
     # Disabled, "Dir.glob" is *waaay* too slow

     Dir.glob(File.join(File.dirname(__FILE__), '../../../plugins', "*","app/controllers","*_controller.rb")).each do |controller|
       # go over all plugin controllers and call "GET show" or "GET index" (if show does not work)
       modulename = File.basename(controller, ".rb").split("_").collect { |i| i.capitalize }.join
       modulepath = File.dirname(controller).split("/")
       # add Namespaces to the modulename. 
       # They are defined as subdirectories in the controller directory
       while modulepath
         namespace = modulepath.pop
         if namespace == "controllers"
           modulepath = nil
         else
           modulename = namespace.capitalize + "::" + modulename
         end
       end
       puts "Checking plugin #{modulename} via HTTP GET requests..."
       ok = system %(cd #{File.dirname(__FILE__)}; export RAILS_PARENT=../../; ruby plugin_test/functional/plugin_show_test.rb --plugin #{modulename} > /dev/null)
       if !ok
#          puts "Trying \"GET index\" cause some plugins do not support \"GET show\"..."
          ok = system %(cd #{File.dirname(__FILE__)}; export RAILS_PARENT=../../; ruby plugin_test/functional/plugin_index_test.rb --plugin #{modulename} > /dev/null)
       end
       unless ok
         warn "plugin #{modulename} does not work correctly.", "Have a look to log/test.log for additional information" 
       else
         puts "plugin #{modulename} works correctly."
       end
     end 
  end
  
  if Error.errors == 0
    puts ""
    puts "**************************************"
    puts "All fine, rest-service is ready to run"
    puts "**************************************"
  else
    puts ""
    puts "*******************************************************"
    puts "Please, fix the above errors before running the service"
    puts "*******************************************************"
  end
end
