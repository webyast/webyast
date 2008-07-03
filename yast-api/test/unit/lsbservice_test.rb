require 'test_helper'

class LsbserviceTest < ActiveSupport::TestCase
  require 'lsbservice'
  # Replace this with your real tests.
  def test_init
    lsb = Lsbservice.new :ntp
    assert true
  end
end
