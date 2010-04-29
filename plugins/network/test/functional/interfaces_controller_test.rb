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
    @model_class = Interface
    Interface.stubs(:find).with('eth0').returns(Interface.new({"bootproto"=>"dhcp"}))
    Interface.stubs(:find).with('eth1').returns(Interface.new({"bootproto"=>"static", "ipaddr"=>"1.2.3.4/24"}))
    @controller = Network::InterfacesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end  

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

# some cases fail because PluginBasicTests expects a singular controller (same as routing test)
#  include PluginBasicTests

end

