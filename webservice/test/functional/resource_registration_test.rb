#
# test/functional/resource_registration_tests.rb
#
require 'test_helper'

class ResourceRegistrationTest < ActiveSupport::TestCase

  require "lib/resource"
  
  fixtures :domains, :resources
  
  # Create resource from .yaml file
  
  test "resource creation" do
    ResourceRegistration.init
    assert Domain.find(:all).empty?
    assert Resource.find(:all).empty?
  end
end
