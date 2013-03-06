# find the rails parent
require File.join(File.dirname(__FILE__), '..', 'config', 'rails_parent')
require File.join(RailsParent.parent, "test","test_helper")
require File.join(RailsParent.parent, "test","validation_assert")
require 'mocha'

require 'systemtime'

module SystemtimeHelpers

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

  READ_RESPONSE = {
    :yapi => {
      "zones"=> TEST_TIMEZONES,
      "timezone"=> "Europe/Prague",
      "utcstatus"=> "UTC",
      "time" => "2012-02-02 - 12:18:00"
    },
    :model => {
      :time      => '12:18:00',
      :date      => '02/02/2012',
      :utcstatus => true,
      :region    => 'Europe',
      :timezone  => 'Czech Republic',
      :config    => 'manual'
    }
  }

  def stub_yapi_read params={}
    return_value = params[:update] ? READ_RESPONSE[:yapi].merge(params[:update]) : READ_RESPONSE[:yapi]
    YastService.stubs(:Call).with("YaPI::TIME::Read", ::Systemtime::TIMEZONE_KEYS).returns return_value
  end

  def stub_yapi_write params
    YastService.stubs(:Call).with("YaPI::TIME::Write", params[:with]).returns(true).once
    YastService.stubs(:Call).with("YaPI::SERVICES::Execute",
      { "name" => ["s","collectd"], "action" => ["s","restart"] })
  end

  def stub_ntp_service action
    YastService.stubs(:Call).with('YaPI::SERVICES::Execute',
      {'custom' => ['b', false],
       'action' => ['s', "#{action.to_s}"],
       'name' => ['s', 'ntp']})
  end

end
