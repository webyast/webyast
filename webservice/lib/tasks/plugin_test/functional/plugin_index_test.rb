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
require "scr"

class Module
  def recursive_const_get(name)
    name.to_s.split("::").inject(self) do |b, c|
      b.const_get(c)
    end
  end
end

class PluginIndexTest < ActionController::TestCase
  fixtures :accounts
  def setup
    puts "Checking #{$pluginname}"
    @controller = Module.recursive_const_get( $pluginname ).new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end
  
  test "access index" do
#    get :index
#    assert_response :success
  end

end
