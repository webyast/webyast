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

class NtpTest < ActiveSupport::TestCase

  def setup    
    Ntp.stubs(:get_server_list).returns("pool.ntp.org")
    @model = Ntp.find
  end

  def test_actions
    assert_not_nil @model.actions
    assert_instance_of(Hash, @model.actions, "action() returns Hash")
  end

  def test_synchronize_ok
    @model.actions[:synchronize] = true
    @model.actions[:synchronize_utc] = true
    YastService.stubs(:Call).with("YaPI::NTP::Synchronize",true,"").once.returns("OK")
    assert_nothing_raised do
      @model.save
    end
  end

  def test_synchronize_error
    @model.actions[:synchronize] = true
    @model.actions[:synchronize_utc] = true
    YastService.stubs(:Call).with("YaPI::NTP::Synchronize",true,"").once.returns("No server defined")
    assert_raise(NtpError) do
      @model.save
    end
  end

  def test_synchronize_timeout
    @model.actions[:synchronize] = true
    @model.actions[:synchronize_utc] = true

    msg_mock = mock()
    msg_mock.stubs(:error_name).returns("org.freedesktop.DBus.Error.NoReply")
    msg_mock.stubs(:params).returns(["test","test"])
    YastService.stubs(:Call).with("YaPI::NTP::Synchronize",true,"").once.raises(DBus::Error,msg_mock)

    assert_nothing_raised do
      @model.save
    end
  end

  def test_unavailable_NTP
    Ntp.stubs(:get_server_list).returns("")
    assert Ntp.find.actions[:ntp_server]
  end
end
