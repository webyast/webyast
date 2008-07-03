require 'test_helper'

class LsbserviceTest < ActiveSupport::TestCase
  require 'lsbservice'
  def test_all
    services = Lsbservice.all
    assert services.size > 0
    assert services[0].is_a? String
  end

  def test_first
    services = Lsbservice.all
    assert services
    first = Lsbservice.new services[0]
    assert first
  end
  def test_ntp
    ntp = Lsbservice.new :ntp
    assert ntp
    assert ntp.status
  end
  def test_error
    begin
      bad = Lsbservice.new :foo_foo_foo
      assert false
    rescue
      assert true
    end
  end
end
