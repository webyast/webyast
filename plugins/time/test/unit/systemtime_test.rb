require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'systemtime'
require 'mocha'

class SystemtimeTest < ActiveSupport::TestCase

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

  READ_ARGUMENTS = {
      "zones"=> "true",
      "timezone"=> "true",
      "utcstatus"=> "true",
      "currenttime" => "true"
    }

  READ_RESPONSE = {
      "zones"=> TEST_TIMEZONES,
      "timezone"=> "Europe/Prague",
      "utcstatus"=> "true",
      "time" => "2009-07-02 - 12:18:00"
    }  

  WRITE_ARGUMENTS_NONE = {
      "timezone"=> "America/Kentucky/Monticello",
      "utcstatus"=> "false"
    }

  WRITE_ARGUMENTS_TIME = {
      "timezone"=> "America/Kentucky/Monticello",
      "utcstatus"=> "false",
      "time" => "2009-07-02 - 12:18:00"
    }

  WRITE_ARGUMENTS_NTP = {
      :timezone=> "America/Kentucky/Monticello",
      :utcstatus=> "false",
    }

  def setup    
    @model = Systemtime.new
  end

  
  def test_getter    
    YastService.stubs(:Call).with("YaPI::TIME::Read",READ_ARGUMENTS).returns(READ_RESPONSE)

    @model = Systemtime.find
    assert_equal("02/07/2009", @model.date)
    assert_equal("12:18:00", @model.time)
    assert_equal("Europe/Prague", @model.timezone)
    assert_equal("true", @model.utcstatus)
    assert_equal(TEST_TIMEZONES,Systemtime.timezones)
  end

  def test_setter_without_time
    x= YastService.stubs(:Call)
    x.with("YaPI::TIME::Write",WRITE_ARGUMENTS_NONE).once
    x.with("YaPI::SERVICES::Execute",{
            "name" => ["s","collectd"],
            "action" => ["s","restart"]
          }).once

    @model.timezone = "America/Kentucky/Monticello"
    @model.utcstatus = "false"
    @model.save
  end

  def test_setter_with_time
    x= YastService.stubs(:Call)
    x.with("YaPI::TIME::Write",WRITE_ARGUMENTS_TIME).returns(true).once
    x.with("YaPI::SERVICES::Execute",{
            "name" => ["s","collectd"],
            "action" => ["s","restart"]
          }).once

    @model.timezone = "America/Kentucky/Monticello"
    @model.utcstatus = "false"
    @model.date = "02/07/2009"
    @model.time = "12:18:00"
    @model.save
  end

  def test_setter_with_move_to_future
    msg_mock = mock()
    msg_mock.stubs(:error_name).returns("org.freedesktop.DBus.Error.NoReply")
    msg_mock.stubs(:params).returns(["test","test"])
    x= YastService.stubs(:Call)
    x.with("YaPI::TIME::Write",WRITE_ARGUMENTS_TIME).raises(DBus::Error,msg_mock).once
#also if error is raised due to time moving collectd must be restarted
    x.with("YaPI::SERVICES::Execute",{
            "name" => ["s","collectd"],
            "action" => ["s","restart"]
          }).once

    @model.timezone = "America/Kentucky/Monticello"
    @model.utcstatus = "false"
    @model.date = "02/07/2009"
    @model.time = "12:18:00"
    assert_nothing_raised do
      @model.save
    end
  end

  def test_xml
    #inject Timezones to set available timezone for direct testing
    def @model.timezones=(val)
      @@timezones=val
    end

    data = READ_RESPONSE
    @model.timezone = data["timezone"]
    @model.utcstatus = data["utcstatus"]
    @model.date = "02/07/2009"
    @model.time = "12:18:00"
    @model.timezones = TEST_TIMEZONES

    response = Hash.from_xml(@model.to_xml)
    response = response["systemtime"]

    assert_equal(data["timezone"], response["timezone"])
    assert_equal(data["utcstatus"], response["utcstatus"])
    assert_equal("12:18:00", response["time"])
    assert_equal("02/07/2009", response["date"])

    zone_response = TEST_TIMEZONES
    zone_response.each { |zone|
      entries = []
      zone["entries"].each { |k,v|
        entries.push({"id"=>k,"name"=>v})
      }
      zone["entries"] = entries
    }

    assert_equal(zone_response.sort { |a,b| a["name"] <=> b["name"] },
      response["timezones"].sort { |a,b| a["name"] <=> b["name"] })
  end

  def test_json
    #inject Timezones to set available timezone for direct testing
    def @model.timezones=(val)
      @@timezones=val
    end
    

    data = READ_RESPONSE
    @model.timezone = data["timezone"]
    @model.utcstatus = data["utcstatus"]
    @model.date = "02/07/2009"
    @model.time = "12:18:00"
    @model.timezones = TEST_TIMEZONES

    assert_not_nil(@model.to_json)
  end

end
