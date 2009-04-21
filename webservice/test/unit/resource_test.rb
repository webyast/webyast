require 'test_helper'

class ResourceTest < ActiveSupport::TestCase
  fixtures :domains, :resources

  test "resource table" do
    network = Domain.find(1)
    # FIXME: should be 'find_by_name_and_domain' -> Rails 2.3 regression ?
    network_routes = Resource.find_by_name_and_domain_id("routes", network)
    assert network_routes
    assert network_routes.domain == network
  end
end
