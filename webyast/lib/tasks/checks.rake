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
    unless version.blank?
      warn v, "install with: zypper in -C '#{package}>=#{version}'" 
    else
      warn v, "install with: zypper in -C '#{package}'"
    end
    Error.inc
    return
  end
  return if version.blank? # just check package, not version
  nvr = v.split "-"
  rel = nvr.pop
  ver = nvr.pop
  ENV['LANG'] = 'C'
  v = `zypper vcmp #{ver} #{version}`
  ENV['LANG'] = old_lang
  if v =~ /is older/
    warn "#{package} not up-to-date (installed:#{ver}) upgrade to #{package}-#{version}"
    Error.inc
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
	  unless package_list[i].strip.start_with?("webyast") ||
                 package_list[i].strip.start_with?("yast2-webservice") ||
                 package_list[i].strip.start_with?("yast2-webclient") ||
                 package_list[i].strip == "nginx"
	    if i+2<package_list.size && package_list[i+1].start_with?(">")
	      packages[package_list[i]] = package_list[i+2] 
	      i += 3
	    else
	      unless package_list[i].start_with?("%{name}") ||
	      	     package_list[i].start_with?("%{version}") ||
		     package_list[i].start_with?("=") ||
                     package_list[i].start_with?("<")
                if package_list[i].strip.start_with?("%") #rpm makro
		  puts "expanding RPM makro #{package_list[i].strip}"
                  `rpm --eval #{package_list[i].strip}`.split().each{ |pk|
		    packages[pk] = "" unless packages.has_key?(pk) 
                  } 
                else
     	          packages[package_list[i]] = "" unless packages.has_key?(package_list[i])
		end
              end
    	      i += 1
	    end
	  else
	    if i+2<package_list.size && package_list[i+1].start_with?(">")
	      i += 3
	    else
    	      i += 1
	    end
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
  
  if Error.errors == 0
    puts ""
    puts "*****************************************"
    puts "All fine, WebYaST/plugin is ready to run"
    puts "*****************************************"
  else
    puts ""
    puts "********************************************************"
    puts "Please, fix the above errors before running the service"
    puts "********************************************************"
  end
end
