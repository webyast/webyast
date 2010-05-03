#--
# Copyright (c) 2009 Novell, Inc.
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
require 'test/unit'
require 'interface'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class InterfacesControllerTest < ActionController::TestCase

  def setup
    YastService.expects(:Call).never
    @model_class = Interface
    eth0 = Interface.new({"bootproto"=>"dhcp"})
    eth1 = Interface.new({"bootproto"=>"static", "ipaddr"=>"1.2.3.4/24"})
    Interface.stubs(:find).with('eth0').returns(eth0)
    Interface.stubs(:find).with('eth1').returns(eth1)
    Interface.stubs(:find).with(:all).returns({"eth0"=>eth0, "eth1"=>eth1})
    @controller = Network::InterfacesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end  

  include CollectionResourceTests

  def test_content1_of_xml
    get :show, :format => 'xml', :id => 'eth0'
    h=Hash.from_xml @response.body
    assert_equal 'dhcp', h['interface']['bootproto']
    assert_nil h['interface']['ipaddr']
  end

  def test_content2_of_xml
    get :show, :format => 'xml', :id => 'eth1'
    h=Hash.from_xml @response.body
    assert_equal 'static', h['interface']['bootproto']
    assert_equal '1.2.3.4/24', h['interface']['ipaddr']
  end

  DATA_GOOD_UI = {
    "interfaces" => {
      "id" => "eth0",
      "bootproto" => "dhcp",
      "ipaddr" => ""
    },
    "id"=>"eth0"
  }
  DATA_GOOD_DOC = {
    "interface" => {
      "id" => "eth0",
      "bootproto" => "dhcp",
      "ipaddr" => ""
    },
    "id"=>"eth0"
  }
  DATA_BAD = {
    "interface" => {
      "id" => "eth0",
      "bootproto" => "static",
      "ipaddr" => "10.1.1.1/666"
    },
    "id"=>"eth0"
  }

  def test_valid_update_as_sent_by_ui
    @model_class.any_instance.stubs(:save).returns true
    put :update, DATA_GOOD_UI
    assert_response 200
  end

  def test_valid_update_as_documented
    @model_class.any_instance.stubs(:save).returns true
    put :update, DATA_GOOD_DOC
    assert_response 200
  end

  def test_validation
    #ensure that nothing is saved
    @model_class.expects(:save).never
    put :update, DATA_BAD
    assert_response 422
  end
  
end

