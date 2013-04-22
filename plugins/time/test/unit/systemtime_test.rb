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

class SystemtimeTest < ActiveSupport::TestCase
  include SystemtimeHelpers

  BROKEN_TIMEZONE = { "timezone" => "" }

  WRITE_TIME_ARGS = {
    :model => {
      :timezone => 'Ukraine (Kiev)',
      :region   => 'Europe',
      :time     => '13:00:00',
      :date     => '02/02/2022',
      :config   => 'manual',
      :utc      => true
    },
    :yapi  => {
      'timezone' => 'Europe/Kiev',
      'currenttime' => '2022-02-02 - 13:00:00',
      'utcstatus'=> 'UTC'
    }
  }

  def test_reading_system_time
    stub_yapi_read
    system_time = Systemtime.find
    assert_equal READ_RESPONSE[:model][:date], system_time.date
    assert_equal READ_RESPONSE[:model][:time], system_time.time
    assert_equal READ_RESPONSE[:model][:timezone], system_time.timezone
    assert_equal READ_RESPONSE[:model][:region], system_time.region
    assert_equal READ_RESPONSE[:model][:utcstatus], system_time.utcstatus
  end

  def test_manual_change_system_time
    stub_yapi_read
    stub_yapi_write :with => WRITE_TIME_ARGS[:yapi]
    system_time = Systemtime.new WRITE_TIME_ARGS[:model]
    stub_ntp_service :stop if system_time.ntpd_running
    assert system_time.save, "Model is not valid, errors: #{system_time.errors.full_messages}"
  end

  def test_loading_without_set_timezone #bnc#582166
    stub_yapi_read :update => BROKEN_TIMEZONE
    system_time = Systemtime.find
    assert_equal "Czech Republic", system_time.timezone
  end

  def test_saving_without_time_manual
    stub_yapi_read
    system_time = Systemtime.new WRITE_TIME_ARGS[:model]
    system_time.time = ''
    assert !system_time.save
    assert system_time.errors[:time].present?, "Expected error message for time attribute"
  end

  def test_setter_without_timezone_manual
    stub_yapi_read
    system_time = Systemtime.find
    system_time.timezone = ''
    assert !system_time.save, "Expected invalid state due to missing timezone"
    assert system_time.errors[:timezone].present?
  end

  def test_setter_with_unknown_region_manual
    stub_yapi_read
    system_time = Systemtime.find
    system_time.region = 'Vysocany'
    assert !system_time.save
    assert system_time.errors[:region].present?
  end

  def test_xml_manual
    stub_yapi_read
    system_time = Systemtime.find
    xml_attributes = Hash.from_xml system_time.to_xml
    xml_attributes['systemtime'].each do |attr, value|
      assert system_time.respond_to?(attr), "Attribute '#{attr}' does not exist"
      assert_equal value, system_time.__send__(attr)
    end
  end

  def change_time_ntp_sync
    stub_yapi_read
    stub_yapi_write :with => WRITE_TIME_ARGS[:yapi]
    system_time = Systemtime.new WRITE_TIME_ARGS[:model].update(:config=>'ntp_sync')
    stub_ntp_service :start unless system_time.ntpd_running
    assert system_time.save
  end

end
