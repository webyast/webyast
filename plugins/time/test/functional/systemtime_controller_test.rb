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
require "systemtime"

class SystemtimeControllerTest < ActionController::TestCase
  fixtures :accounts

    INITIAL_DATA = {
      :timezone => "Europe/Prague",
      :time => "12:18:00",
      :date => "02/07/2009",
      :utcstatus => "true" }
    TEST_TIMEZONES = [{
      "name" => "Europe",
      "central" => "Europe/Prague",
      "entries" => {
        "Europe/Prague" => "Czech Republic",
        "Europe/Kiev" => "Ukraine (Kiev)"
      }
    },
    {
      "name" => "USA",
      "central" => "America/Chicago",
      "entries" => {
        "America/Chicago" => "Central (Chicago)",
        "America/Kentucky/Monticello" => "Kentucky (Monticello)"
      }
    }
    ]
    DATA = {:systemtime => {
      :timezone => "Europe/Prague",
      :utcstatus => "true"
    }}

  def setup
    @model_class = Systemtime
    
    time_mock = Systemtime.new(INITIAL_DATA)
    time_mock.timezones = TEST_TIMEZONES
    Systemtime.stubs(:find).returns(time_mock)

    @controller = SystemtimeController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @data = DATA
  end  

  include PluginBasicTests
  
  def test_update
    mock_save
    put :update, DATA
    assert_response :success
  end

  def test_create
    mock_save
    put :create, DATA
    assert_response :success
  end

  def mock_save
    YastService.stubs(:Call).with {
      |params,settings|
      ret = params == "YaPI::TIME::Write" &&
        settings["timezone"] == DATA[:systemtime][:timezone] &&
        settings["utcstatus"] == DATA[:systemtime][:utcstatus] &&
        ! settings.include?("currenttime")
      ret2 = params == "YaPI::SERVICES::Execute"
      return ret || ret2
    }
    Systemtime.stubs(:permission_check)
  end
end
