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

  NEW_TIMEZONE = {
    :model => {
      :region   => 'USA',
      :timezone => 'Kentucky (Monticello)',
      :utcstatus => true
    },
    :yapi => {'timezone' => 'America/Kentucky/Monticello'}
  }

  NEW_TIME_MANUAL = {
    :model => {
      :config  => 'manual',
      :time    => '22:22:22',
      :date    => '02/02/2012'
    },
    :yapi => {
      'currenttime' => '2222-02-02 - 22:22:22'
    }
  }

  def setup
    devise_sign_in
    TimeController.any_instance.stubs(:authorize!).returns(true)
  end

  def teardown
    Mocha::Mockery.instance.stubba.unstub_all
  end

  def test_index_html
    stub_yapi_read
    get :index
    assert_response :success
    assert_not_nil assigns(:system_time)
  end

  def test_update_timezone_html
    stub_yapi_read
    stub_yapi_write :with => WRITE_RESPONSE.update(NEW_TIMEZONE[:yapi])
    get :index
    assert_response :success
    post :create, :systemtime => NEW_TIMEZONE[:model]
    assert_response :redirect
    assert_redirected_to :controller => :time, :action => :index
  end

  def test_update_manual_time_html
    stub_yapi_read
    stub_yapi_write :with  => WRITE_RESPONSE.update(NEW_TIME_MANUAL[:yapi])
    post :create, :systemtime => NEW_TIME_MANUAL[:model].update NEW_TIMEZONE[:model]
    assert_response :redirect
    assert_redirected_to :controller => :time, :action => :index
  end


  #TODO
  def test_update_ntp_time_html
  end

end
__END__
  def test_update
    mock_save
    mime = Mime::XML
    DATA[:format]='xml'
    put :update, DATA
    assert_response :success
  end

  def test_create
    mock_save
    mime = Mime::XML
    DATA[:format]='xml'
    put :create, DATA
    assert_response :success
  end

  def mock_save(use_ntp = false)

    YastService.stubs(:Call).with("YaPI::TIME::Write",{}).returns(true)
    YastService.stubs(:Call).with("YaPI::TIME::Write", {"utcstatus"=>"localtime", "timezone"=>"Europe/Prague", "currenttime"=>"2011-16-08 - 14:07:26"}).returns(true)

    unless use_ntp
      YastService.stubs(:Call).with("YaPI::SERVICES::Execute", {"name"=>["s", "ntp"], "action"=>["s", "stop"], "custom"=>["b", false]}).once.returns(true)
    else
      YastService.stubs(:Call).with('YaPI::NTP::Synchronize', true, 'de.pool.ntp.org').once.returns("OK")
      YastService.stubs(:Call).with("YaPI::SERVICES::Execute", {"name"=>["s", "ntp"], "action"=>["s", "start"], "custom"=>["b", false]}).once.returns(true)
    end

    YastService.stubs(:Call).with("YaPI::SERVICES::Execute", {'name' => ['s', 'collectd'], 'action' => ['s', 'restart']}).once.returns(true)
  end

  def test_commit
    mock_save
    Ntp.expects(:save).never #ntp is not called if time settings is manual
    post :update, DATA
    assert_response :redirect
    assert_redirected_to :controller => "time", :action => "index"
  end

  def test_ntp
    mock_save(use_ntp=true)
    post :update, {"region"=>"Europe",
                   "utcstatus"=>"true",
                   "config"=>"ntp_sync",
                   "ntp_server"=>"de.pool.ntp.org",
                   "timezone" => "Europe/Prague"}
    assert_response :redirect
    assert_redirected_to :controller => "controlpanel", :action => "index"
  end

  INITIAL_DATA = {
    :timezone => "Czech Republic",
    :region   => "Europe",
    :time     => "12:00:00",
    :date     => "02/02/2012",
    :utcstatus=> "true"
  }

  REQUEST_DATA = {
    'systemtime' => {
      "config"   => "manual",
      "date"     => "16/08/2011",
      "time"     => "14:07:26",
      "timezone" => "Germany",
      "region"   => "Europe"
    }
  }

end
