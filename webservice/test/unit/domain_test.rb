require 'test_helper'

class DomainTest < ActiveSupport::TestCase
  fixtures :domains

  # simple Domain tests
  # assume 3 fixture entries
  
  test "domain table" do
    network = Domain.find(1)
    assert network
    # to_s should return the name
    assert network.to_s == network.name
    
    printer = Domain.find(2)
    assert printer
    
    storage = Domain.find(3)
    assert storage
  end
end
	