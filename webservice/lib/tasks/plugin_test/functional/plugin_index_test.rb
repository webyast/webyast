require 'fileutils'
require 'getoptlong'

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


require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"

def normalize_name name
    name.split("_").collect { |i| i.capitalize }.join
end

class PluginIndexTest < ActionController::TestCase
  fixtures :accounts
  def setup
    classname = normalize_name $pluginname
    puts "Checking #{classname}"
    @controller = Kernel.const_get( classname ).new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end
  
  test "access index" do
    get :index
    assert_response :success
  end

end
