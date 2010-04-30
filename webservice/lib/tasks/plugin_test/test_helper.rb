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

rails_parent = ENV["RAILS_PARENT"]
unless rails_parent
  if File.directory?("../../webservice/")
     $stderr.puts "Taking ../../webservice/ for RAILS_PARENT"  
     rails_parent="../../webservice/"
  else
     $stderr.puts "Please set RAILS_PARENT environment"
     exit
  end
end

require File.expand_path(rails_parent + "/test/test_helper")
require 'fileutils'
require 'getoptlong'
require 'test/unit'

options = GetoptLong.new(
  [ "--plugin",   GetoptLong::REQUIRED_ARGUMENT ]
)

$pluginname = nil
begin
options.each do |opt, arg|
  case opt
    when "--plugin": $pluginname = arg
    else
	STDERR.puts "Ignoring unrecognized option #{opt}"
  end
end
rescue
end

class Module
  def recursive_const_get(name)
    name.to_s.split("::").inject(self) do |b, c|
      b.const_get(c)
    end
  end
end
