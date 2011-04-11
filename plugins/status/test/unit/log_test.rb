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
require 'mocha'
require 'yast/config_file'
require 'rexml/document'

def xml_cmp a, b
  a = REXML::Document.new(a.to_s)
  b = REXML::Document.new(b.to_s)

  normalized = Class.new(REXML::Formatters::Pretty) do
    def write_text(node, output)
      super(node.to_s.strip, output)
    end
  end

  normalized.new(indentation=0,ie_hack=false).write(node=a, a_normalized='')
  normalized.new(indentation=0,ie_hack=false).write(node=b, b_normalized='')

  a_normalized == b_normalized
end

class LogTest < ActiveSupport::TestCase

  READ_RESPONSE = 
{"`position"=>"2721", "`value"=>"Feb  1 21:29:26 e68 rsyslogd: -- MARK --\nFeb  1 21:49:26 e68 rsyslogd: -- MARK --\nFeb  1 22:09:12 e68 smartd[2773]: Device: /dev/sda [SAT], SMART Usage Attribute: 194 Temperature_Celsius changed from 109 to 110\n"}

  def setup
    Log.stubs(:parse_config).returns(YaST::ConfigFile.new(File.expand_path(File.dirname(__FILE__) + "/../../doc/logs.yml") ))
  end

  def test_finders
    ret = Log.find(:all)
    assert_equal 1, ret.size
    assert ret.map{|x| x.id}.include?('system')
    assert ret.map{|x| x.path}.include?("/var/log/messages")
    assert ret.map{|x| x.description}.include?('System messages')
    
    ret = Log.find('system')
    assert ret.id == 'system'
    assert ret.path == "/var/log/messages"
    assert ret.description == 'System messages'

    ret = Log.find('notfound')
    assert_equal nil, ret
  end

  def test_read_log_file
    YastService.stubs(:Call).with("LogFile::Read", ['s', 'system'], ['s', '0'], ['s', '50']).returns(READ_RESPONSE)
    ret = Log.find('system')
    ret.evaluate_content()

    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.log do
      xml.id "system"
      xml.path "/var/log/messages"
      xml.description "System messages"
      xml.content do
        xml.value "Feb  1 21:29:26 e68 rsyslogd: -- MARK --\nFeb  1 21:49:26 e68 rsyslogd: -- MARK --\nFeb  1 22:09:12 e68 smartd[2773]: Device: /dev/sda [SAT], SMART Usage Attribute: 194 Temperature_Celsius changed from 109 to 110\n"
        xml.position "2721"
      end
    end

    log_xml = ret.to_xml()
#    puts "   #{log_xml.inspect}"
    should_xml = xml.target!
#    puts "   #{should_xml.inspect}"    
    assert xml_cmp log_xml, should_xml

  end
  

end
