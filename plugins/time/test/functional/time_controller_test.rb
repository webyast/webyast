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
require File.join(RailsParent.parent, "test","devise_helper")

class TimeControllerTest < ActionController::TestCase
  include SystemtimeHelpers

  def setup
    devise_sign_in
    TimeController.any_instance.stubs(:authorize!).returns(true)
  end

  def teardown
    Mocha::Mockery.instance.stubba.unstub_all
  end

  def test_index
    stub_yapi_read
    get :index
    assert_response :success
    assert_not_nil assigns(:system_time)
  end

  TIMEZONE = {
    :model => {
      :region   => 'USA',
      :timezone => 'Kentucky (Monticello)',
      :utcstatus => true
    },
    :yapi => {
      'timezone' => 'America/Kentucky/Monticello',
      'utcstatus' => 'UTC'
    }
  }

  def test_update_timezone
    stub_yapi_read
    stub_yapi_write :with => TIMEZONE[:yapi]
    post :create, :systemtime => TIMEZONE[:model]
    assert_response :redirect
    assert_redirected_to :controller => :time, :action => :index
  end

  TIME_MANUAL = {
    :model => {
      :config  => 'manual',
      :time    => '22:22:22',
      :date    => '02/02/2000'
    },
    :yapi => {
      'currenttime' => '2000-02-02 - 22:22:22'
    }
  }
  def test_update_manual_time
    stub_yapi_read
    stub_yapi_write :with  => TIMEZONE[:yapi].merge(TIME_MANUAL[:yapi])
    YastService.stubs(:Call).with("YaPI::SERVICES::Execute",
    {"name"=>["s", "ntp"], "action"=>["s", "stop"], "custom"=>["b", false]}).once.returns(true)
    Ntp.expects(:save).never
    post :create, :systemtime => TIMEZONE[:model].merge(TIME_MANUAL[:model])
    assert_response :redirect
    assert_redirected_to :controller => :time, :action => :index
  end

  TIME_NTP = {
    :model => {
      :config     => 'ntp_sync',
      :ntp_server => 'time.ntpserver.com'
    },
    :yapi  => {
      'ntp_server' => 'time.ntpserver.com'
    }
  }

  def test_update_ntp_time
    stub_yapi_read
    YastService.stubs(:Call).with("YaPI::SERVICES::Execute",
      {"name"=>["s", "ntp"], "action"=>["s", "start"], "custom"=>["b", false]}).once.returns(true)
    Ntp.any_instance.stubs(:update).once
    post :create, :systemtime => TIMEZONE[:model].merge(TIME_NTP[:model])
    assert_response :redirect
    assert_redirected_to :controller => :time, :action => :index
  end

end
