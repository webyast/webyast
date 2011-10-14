#--
# Copyright (c) 2009-2010 Novell, Inc.
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'system'

class SystemTest < ActiveSupport::TestCase

  def setup
    @model = System.instance
    @model.stubs(:consolekit_power_management).with(:reboot).returns(true)
    @model.stubs(:consolekit_power_management).with(:shutdown).returns(true)
  end

  def test_actions
    assert_not_nil @model.actions
    assert_instance_of(Hash, @model.actions, "action() returns Hash")
  end

  def test_reboot
    ret = @model.reboot
    assert ret
    assert @model.actions[:reboot]
  end

  def test_shutdown
    ret = @model.shutdown
    assert ret
    assert @model.actions[:shutdown]
  end

end

