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
require 'systemtime'

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

  READ_RESPONSE = {
      "zones"=> TEST_TIMEZONES,
      "timezone"=> "Europe/Prague",
      "utcstatus"=> "UTC",
      "time" => "2009-07-02 - 12:18:00"
    }

  READ_RESPONSE_BROKEN_TIMEZONE = {
      "zones"=> TEST_TIMEZONES,
      "timezone"=> "",
      "utcstatus"=> "UTC",
      "time" => "2009-07-02 - 12:18:00"
    }

  WRITE_ARGUMENTS_TIME = {
      "timezone"=> "America/Kentucky/Monticello",
      "utcstatus"=> "local",
      "time" => "2009-07-02 - 12:18:00"
    }

  WRITE_ARGUMENTS_NTP = {
      :timezone=> "America/Kentucky/Monticello",
      :utcstatus=> "local",
    }

  def setup
    Systemtime.stubs(:permission_check)
  end

  def stub_yapi_read params
    YastService.stubs(:Call).with("YaPI::TIME::Read", Systemtime::TIMEZONE_KEYS).returns params[:returns]
  end

  def stub_yapi_write params
    YastService.stubs(:Call).with("YaPI::TIME::Write", params[:with]).returns(true).once
    YastService.stubs(:Call).with("YaPI::SERVICES::Execute",
      { "name" => ["s","collectd"], "action" => ["s","restart"] }).once
  end

  def test_reading_system_time
    stub_yapi_read :returns => READ_RESPONSE
    model = Systemtime.find
    assert_equal "02/07/2009", model.date
    assert_equal "12:18:00", model.time
    assert_equal "Czech Republic", model.timezone
    assert_equal true, model.utcstatus
  end

  #TODO
  def test_writing_system_time
    stub_yapi_read :returns => READ_RESPONSE
    model = Systemtime.find
  end

  def test_loading_without_set_timezone #bnc#582166
    stub_yapi_read :returns => READ_RESPONSE_BROKEN_TIMEZONE
    model = Systemtime.find
    assert_equal "Czech Republic", model.timezone
  end

  def test_saving_without_time
    stub_yapi_read :returns => READ_RESPONSE
    model = Systemtime.find
    model.time = ''
    assert !model.save
    assert model.errors[:time].present?
  end

  def test_setter_without_timezone
    stub_yapi_read :returns => READ_RESPONSE
    model = Systemtime.find
    model.timezone = ''
    assert !model.save
    assert model.errors[:timezone].present?
  end

  def test_setter_with_unknown_region
    stub_yapi_read :returns => READ_RESPONSE
    model = Systemtime.find
    model.region = 'Vysocany'
    assert !model.save
    assert model.errors[:region].present?
  end

  def test_xml
    stub_yapi_read :returns => READ_RESPONSE
    model = Systemtime.find
    xml_attributes = Hash.from_xml model.to_xml
    xml_attributes[:systemtime].each_pair do |attr, value|
      assert model.respond_to? :attr
      assert_equal value, model.__send__ value
    end
  end

end
