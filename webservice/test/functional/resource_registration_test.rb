#
# test/functional/resource_registration_tests.rb
#
require 'test_helper'

class ResourceRegistrationTest < ActiveSupport::TestCase

  require "lib/resource"
  
  fixtures :domains, :resources
  
  # ResourceRegistration.init drops all database content
  
  test "resource initialization" do
    ResourceRegistration.init
    assert Domain.find(:all).empty?
    assert Resource.find(:all).empty?
  end
  
  # Create resources from .yaml file
  
  test "resource creation" do
    ResourceRegistration.init
    ResourceRegistration.register_all ".", "resource_fixtures/good"
      
    assert !Domain.find(:all).empty?
    assert !Resource.find(:all).empty?
  end
  
  # Check if file name sets resource name
  
  test "resource name creation" do
    ResourceRegistration.init
    ResourceRegistration.register_all ".", "resource_fixtures/check_name"
      
    domains = Domain.find(:all)
    assert domains
    assert domains.size == 1
    assert domains[0].name == "domain"
    
    resources = Resource.find(:all)
    assert resources
    assert resources.size == 1
    assert resources[0].name == "resource"
  end
  
  # Check if parent dir name sets domain name
  
  test "resource domain creation" do
    ResourceRegistration.init
    ResourceRegistration.register_all ".", "resource_fixtures/check_domain"
      
    domains = Domain.find(:all)
    assert domains
    assert domains.size == 1
    assert domains[0].name == "domain"
    
    resources = Resource.find(:all)
    assert resources
    assert resources.size == 1
    assert resources[0].name == "resource"
  end
  
  # Catch errors in bad_domain
  
  test "resource exception" do
    ResourceRegistration.init
    assert_raise RuntimeError do
      ResourceRegistration.register_all ".", "test/resource_fixtures/bad_domain"
    end
  end
end
