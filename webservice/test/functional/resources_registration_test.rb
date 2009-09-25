#
# test/functional/resource_registration_test.rb
#
# This tests the mapping from resource descriptions (yaml files) to the database
#
# See resource_route_test.rb for resource route tests.
#
class TestPlugin
  attr_reader :directory
  def initialize path
    @directory = File.join(File.dirname(__FILE__), "..", path)
  end
end

unless defined? RESOURCE_REGISTRATION_TESTING
  RESOURCE_REGISTRATION_TESTING = true # prevent plugin registration in environment.rb
end

require File.join(File.dirname(__FILE__), "..", "test_helper")
require File.join(File.dirname(__FILE__), "..", "..", "lib", "resource_registration")

class ResourceRegistrationTest < ActiveSupport::TestCase

  # Create resources from .yml file
  
  test "resource creation" do
    plugin = TestPlugin.new "resource_fixtures/good"
    ResourceRegistration.register_plugin plugin
      
    assert !ResourceRegistration.resources.empty?
    assert_not_nil ResourceRegistration.resources["org.opensuse.yast.modules.yapi.time"][0]
    time = ResourceRegistration.resources["org.opensuse.yast.modules.yapi.time"][0]
    assert_equal "systemtimes", time[:controller]
    assert time[:singular]
  end
  
  # Create nested resources from .yml file
  
  test "resource creation nested" do
    plugin = TestPlugin.new "resource_fixtures/nested"
    ResourceRegistration.register_plugin plugin
      
    assert !ResourceRegistration.resources.empty?
  end
  
  # Catch errors in interface
  
  test "bad interface" do
    plugin = TestPlugin.new "resource_fixtures/bad_interface"
    assert_raise ResourceRegistrationFormatError do
      ResourceRegistration.register_plugin plugin
    end
  end
  
  test "no interface" do
    plugin = TestPlugin.new "resource_fixtures/no_interface"
    assert_raise ResourceRegistrationFormatError do
      ResourceRegistration.register_plugin plugin
    end
  end
  
  # Catch errors in controller
  
  test "no controller" do
    plugin = TestPlugin.new "resource_fixtures/no_controller"
    assert_raise ResourceRegistrationFormatError do
      ResourceRegistration.register_plugin plugin
    end
  end
  
  test "bad controller, go fix web-client to use modules" do
    plugin = TestPlugin.new "resource_fixtures/bad_controller"
#    assert_raise RuntimeError do
      ResourceRegistration.register_plugin plugin
#    end
  end
  
  # Catch pluralization error
  
  test "interface is singular but not flagged as such" do
    plugin = TestPlugin.new "resource_fixtures/bad_singular"
    assert_raise ResourceRegistrationFormatError do
      ResourceRegistration.register_plugin plugin
    end
  end

  # Catch nested singular, which is not supported (yet?)
  
  test "nesting inside a singular resource" do
    plugin = TestPlugin.new "resource_fixtures/nested_singular"
    assert_raise ResourceRegistrationFormatError do
      ResourceRegistration.register_plugin plugin
    end
  end
  
  # Pass bad values to register_plugin
  
  test "pass bad values to register_plugin" do
    assert_raise NoMethodError do
      ResourceRegistration.register_plugin nil
    end
    assert_raise NoMethodError do
      ResourceRegistration.register_plugin 1
    end
    assert_raise NoMethodError do
      ResourceRegistration.register_plugin true
    end
  end
  
  # Catch non-existing file
  
  test "file does not exist" do
    assert_raise Errno::ENOENT do
      ResourceRegistration.register "does_not_exist"
    end
  end
  
  # Bad call to register
  
  test "passing bad values to register" do
    assert_raise TypeError do
      ResourceRegistration.register nil
    end
    assert_raise TypeError do
      ResourceRegistration.register 1
    end
    assert_raise TypeError do
      ResourceRegistration.register true
    end
  end

  # Complain about private routing
  
  test "complain about private routing" do
    plugin = TestPlugin.new "resource_fixtures/private_routing"
    assert_raise ResourceRegistrationFormatError do
      ResourceRegistration.register_plugin plugin
    end
  end

end
