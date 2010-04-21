#--
# Webyast Webservice framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

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

TEST_STATUS = 'testing status'
TEST_PROGRESS = 10
TEST_SUBPROGRESS = 5

class BackgroundStatusTest < ActiveSupport::TestCase
  def setup
     @bs = BackgroundStatus.new
  end

  def test_assignemnt
    @bs.status = TEST_STATUS
    @bs.progress = TEST_PROGRESS
    @bs.subprogress = TEST_SUBPROGRESS

    assert_equal TEST_STATUS, @bs.status
    assert_equal TEST_PROGRESS, @bs.progress
    assert_equal TEST_SUBPROGRESS, @bs.subprogress
  end

  def test_observing
    ot = ObserverTest.new(@bs)

    # test progress change
    ot.reset
    @bs.progress = TEST_PROGRESS
    assert ot.changed?

    ot.reset
    @bs.subprogress = TEST_SUBPROGRESS
    assert ot.changed?

    ot.reset
    @bs.status = TEST_STATUS
    assert ot.changed?

    # no change must not emit change event
    ot.reset
    @bs.progress = TEST_PROGRESS
    assert !ot.changed?

    ot.reset
    @bs.subprogress = TEST_SUBPROGRESS
    assert !ot.changed?

    ot.reset
    @bs.status = TEST_STATUS
    assert !ot.changed?
  end

  def test_serialization
    assert @bs.to_xml

    expected_ret = {"subprogress" => @bs.subprogress, "progress" => @bs.progress, "status" => @bs.status }

    assert_equal expected_ret, Hash.from_xml(@bs.to_xml)["background_status"]
  end

end
