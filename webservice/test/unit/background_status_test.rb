require File.dirname(__FILE__) + '/../test_helper'

class ObserverTest
  def initialize(observable)
    observable.add_observer(self)
    reset
  end

  def update(observable)
    @changed = true
  end

  def changed?
    @changed
  end

  def reset
    @changed = false
  end
end

class BackgroundStatusTest < ActiveSupport::TestCase
  def setup
     @bs = BackgroundStatus.new
  end

  def test_assignemnt
    s = 'status'
    p = 10
    sp = 5
    @bs.status = s
    @bs.progress = p
    @bs.subprogress = sp

    assert_equal s, @bs.status
    assert_equal p, @bs.progress
    assert_equal sp, @bs.subprogress
  end

  def test_observing
    ot = ObserverTest.new(@bs)
    s = 'dummy status'
    p = 10
    sp = 5

    # test progress change
    ot.reset
    @bs.progress = p
    assert ot.changed?

    ot.reset
    @bs.subprogress = sp
    assert ot.changed?

    ot.reset
    @bs.status = s
    assert ot.changed?

    # no change must not emit change event
    ot.reset
    @bs.progress = p
    assert !ot.changed?

    ot.reset
    @bs.subprogress = sp
    assert !ot.changed?

    ot.reset
    @bs.status = s
    assert !ot.changed?
  end

  def test_serialization
    assert @bs.to_xml

    expected_ret = {"subprogress" => @bs.subprogress, "progress" => @bs.progress, "status" => @bs.status }

    assert_equal expected_ret, Hash.from_xml(@bs.to_xml)["background_status"]
  end

end
