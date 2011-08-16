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

class TimeControllerTest < ActionController::TestCase
  fixtures :accounts

    INITIAL_DATA = {
      :timezone => "Europe/Prague",
      :time => "12:18:00",
      :date => "02/07/2009",
      :utcstatus => "true" }
    TEST_TIMEZONES = [
{"name"=>"Europe", "entries"=>[{"name"=>"Uzhgorod", "id"=>"Europe/Uzhgorod"}, {"name"=>"Russia (Moscow)", "id"=>"Europe/Moscow"}, {"name"=>"Jersey", "id"=>"Europe/Jersey"}, {"name"=>"Belgium", "id"=>"Europe/Brussels"}, {"name"=>"Netherlands", "id"=>"Europe/Amsterdam"}, {"name"=>"Miquelon", "id"=>"America/Miquelon"}, {"name"=>"Ukraine (Zaporozhye)", "id"=>"Europe/Zaporozhye"}, {"name"=>"France", "id"=>"Europe/Paris"}, {"name"=>"Norway", "id"=>"Europe/Oslo"}, {"name"=>"Malta", "id"=>"Europe/Malta"}, {"name"=>"Finland", "id"=>"Europe/Helsinki"}, {"name"=>"Greece", "id"=>"Europe/Athens"}, {"name"=>"Canary Islands", "id"=>"Atlantic/Canary"}, {"name"=>"Macedonia", "id"=>"Europe/Skopje"}, {"name"=>"Monaco", "id"=>"Europe/Monaco"}, {"name"=>"Iceland", "id"=>"Atlantic/Reykjavik"}, {"name"=>"San Marino", "id"=>"Europe/San_Marino"}, {"name"=>"Italy", "id"=>"Europe/Rome"}, {"name"=>"Portugal", "id"=>"Europe/Lisbon"}, {"name"=>"Turkey", "id"=>"Europe/Istanbul"}, {"name"=>"Ireland", "id"=>"Europe/Dublin"}, {"name"=>"Slovakia", "id"=>"Europe/Bratislava"}, {"name"=>"Germany", "id"=>"Europe/Berlin"}, {"name"=>"Spain", "id"=>"Europe/Madrid"}, {"name"=>"Isle of Man", "id"=>"Europe/Isle_of_Man"}, {"name"=>"Guernsey", "id"=>"Europe/Guernsey"}, {"name"=>"Denmark", "id"=>"Europe/Copenhagen"}, {"name"=>"Switzerland", "id"=>"Europe/Zurich"}, {"name"=>"Croatia", "id"=>"Europe/Zagreb"}, {"name"=>"Estonia", "id"=>"Europe/Tallinn"}, {"name"=>"Ukraine (Kiev)", "id"=>"Europe/Kiev"}, {"name"=>"Poland", "id"=>"Europe/Warsaw"}, {"name"=>"Lithuania", "id"=>"Europe/Vilnius"}, {"name"=>"Vatican", "id"=>"Europe/Vatican"}, {"name"=>"Czech Republic", "id"=>"Europe/Prague"}, {"name"=>"Aaland Islands", "id"=>"Europe/Mariehamn"}, {"name"=>"Russia (Kaliningrad)", "id"=>"Europe/Kaliningrad"}, {"name"=>"Gibraltar", "id"=>"Europe/Gibraltar"}, {"name"=>"Serbia", "id"=>"Europe/Belgrade"}, {"name"=>"Austria", "id"=>"Europe/Vienna"}, {"name"=>"Liechtenstein", "id"=>"Europe/Vaduz"}, {"name"=>"Luxembourg", "id"=>"Europe/Luxembourg"}, {"name"=>"Slovenia", "id"=>"Europe/Ljubljana"}, {"name"=>"Andorra", "id"=>"Europe/Andorra"}, {"name"=>"Azores", "id"=>"Atlantic/Azores"}, {"name"=>"Ukraine (Simferopol)", "id"=>"Europe/Simferopol"}, {"name"=>"Belarus", "id"=>"Europe/Minsk"}, {"name"=>"United Kingdom", "id"=>"Europe/London"}, {"name"=>"Romania", "id"=>"Europe/Bucharest"}, {"name"=>"Russia (Volgograd)", "id"=>"Europe/Volgograd"}, {"name"=>"Albania", "id"=>"Europe/Tirane"}, {"name"=>"Sweden", "id"=>"Europe/Stockholm"}, {"name"=>"Bulgaria", "id"=>"Europe/Sofia"}, {"name"=>"Bosnia & Herzegovina", "id"=>"Europe/Sarajevo"}, {"name"=>"Russia (Samara)", "id"=>"Europe/Samara"}, {"name"=>"Latvia", "id"=>"Europe/Riga"}, {"name"=>"Montenegro", "id"=>"Europe/Podgorica"}, {"name"=>"Moldova", "id"=>"Europe/Chisinau"}, {"name"=>"Hungary", "id"=>"Europe/Budapest"}], "central"=>"Europe/Prague"
    },
{"name"=>"USA", "entries"=>[{"name"=>"Hawaii (Honolulu)", "id"=>"Pacific/Honolulu"}, {"name"=>"Central (Chicago)", "id"=>"America/Chicago"}, {"name"=>"Alaska (Anchorage)", "id"=>"America/Anchorage"}, {"name"=>"Kentucky (Monticello)", "id"=>"America/Kentucky/Monticello"}, {"name"=>"Juneau", "id"=>"America/Juneau"}, {"name"=>"Indiana (Petersburg)", "id"=>"America/Indiana/Petersburg"}, {"name"=>"East Indiana (Indianapolis)", "id"=>"America/Indiana/Indianapolis"}, {"name"=>"Shiprock", "id"=>"America/Shiprock"}, {"name"=>"Pacific (Los Angeles)", "id"=>"America/Los_Angeles"}, {"name"=>"Indiana (Marengo)", "id"=>"America/Indiana/Marengo"}, {"name"=>"Samoa (Pago Pago)", "id"=>"Pacific/Pago_Pago"}, {"name"=>"Virgin Islands (St Thomas)", "id"=>"America/St_Thomas"}, {"name"=>"North Dakota (New Salem)", "id"=>"America/North_Dakota/New_Salem"}, {"name"=>"Indiana (Vevay)", "id"=>"America/Indiana/Vevay"}, {"name"=>"Mountain (Denver)", "id"=>"America/Denver"}, {"name"=>"Menominee", "id"=>"America/Menominee"}, {"name"=>"Indiana (Winamac)", "id"=>"America/Indiana/Winamac"}, {"name"=>"Boise", "id"=>"America/Boise"}, {"name"=>"Arizona (Phoenix)", "id"=>"America/Phoenix"}, {"name"=>"Indiana (Vincennes)", "id"=>"America/Indiana/Vincennes"}, {"name"=>"Aleutian (Adak)", "id"=>"America/Adak"}, {"name"=>"Eastern (New York)", "id"=>"America/New_York"}, {"name"=>"Michigan (Detroit)", "id"=>"America/Detroit"}, {"name"=>"Puerto Rico", "id"=>"America/Puerto_Rico"}, {"name"=>"Nome", "id"=>"America/Nome"}, {"name"=>"Kentucky (Louisville)", "id"=>"America/Kentucky/Louisville"}, {"name"=>"Yakutat", "id"=>"America/Yakutat"}, {"name"=>"North Dakota (Center)", "id"=>"America/North_Dakota/Center"}, {"name"=>"Indiana Starke (Knox)", "id"=>"America/Indiana/Knox"}, {"name"=>"Indiana (Tell City)", "id"=>"America/Indiana/Tell_City"}], "central"=>"America/Chicago"}
    ]
    DATA = {
       "timeconfig"=>"manual", 
       "date"=>{"date"=>"16/08/2011"}, 
       "currenttime"=>"14:07:26",
       "timezone"=>"Europe/Prague", "region"=>"Europe" }

  def setup
    @model_class = Systemtime
    
    time_mock = Systemtime.new(INITIAL_DATA)
    time_mock.timezones = TEST_TIMEZONES
    Systemtime.stubs(:find).returns(time_mock)

    @controller = TimeController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @data = DATA
  end  

  include PluginBasicTests
  
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

  def mock_save
    YastService.stubs(:Call).with("YaPI::TIME::Write",{}).returns(true)
    YastService.stubs(:Call).with("YaPI::TIME::Write",
        {"utcstatus"=>"localtime", 
         "timezone"=>"Europe/Prague", 
          "currenttime"=>"2011-16-08 - 14:07:26"}).returns(true)
    YastService.stubs(:Call).with("YaPI::SERVICES::Execute",
        {"name"=>["s", "ntp"], "action"=>["s", "stop"], 
         "custom"=>["b", false]}).once.returns(true)
    YastService.stubs(:Call).with("YaPI::SERVICES::Execute",
        {'name' => ['s', 'collectd'], 'action' => ['s', 'restart']
        }).once.returns(true)
    Time.stubs(:permission_check)
  end
end
