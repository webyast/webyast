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
require "scr"

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
