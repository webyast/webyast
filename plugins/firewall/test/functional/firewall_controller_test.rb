##--
## Copyright (c) 2009-2010 Novell, Inc.
## 
## All Rights Reserved.
## 
## This program is free software; you can redistribute it and/or modify it
## under the terms of version 2 of the GNU General Public License
## as published by the Free Software Foundation.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program; if not, contact Novell, Inc.
## 
## To contact Novell about this file by physical or electronic mail,
## you may find current contact information at www.novell.com
##++

require File.join(File.dirname(__FILE__),"..", "test_helper")
require File.join(RailsParent.parent, "test","devise_helper")

class FirewallControllerTest < ActionController::TestCase
                       
  FIREWALL = { "use_firewall" => true, 
    "fw_services" => [
      {"name"=>"MySQL server", "id"=>"service:mysql", "description"=>"opens ports for MySQL", "allowed"=>true}, 
      {"name"=>"mDNS/Bonjour support for HPLIP", "id"=>"service:hplip", "description"=>"mDNS/Bonjour", "allowed"=>true}, 
      {"name"=>"bind DNS server", "id"=>"service:bind", "description"=>"DNS server", "allowed"=>false}, 
      {"name"=>"PostgreSQL Server", "id"=>"service:postgresql", "description"=>"PostgreSQL server.", "allowed"=>false}
    ]
  }
  
  DATA = { 
    "firewall_service:mysql"=>"false", 
    "firewall_service:hplip"=>"false", 
    "firewall"=>{"use_firewall"=>"false"}
  }
  
  OK_RESULT = {"saved_ok" => true, "error" => ""}
  
  def setup
    devise_sign_in 
    Firewall.stubs(:find).returns(Firewall.new(FIREWALL))
    Firewall.any_instance.stubs(:save).returns(OK_RESULT)
    FirewallController.any_instance.stubs(:permission_check).with("org.opensuse.yast.modules.yapi.firewall.read").returns(true)
    FirewallController.any_instance.stubs(:permission_check).with("org.opensuse.yast.modules.yapi.firewall.write").returns(true)
  end
  
  include PluginBasicTests

  @model = Firewall

  test "should get index" do
    get :index
    assert_response :success
  end
  
   test "should get show" do
    ret = get :show, :format => "xml"
    ret_hash = Hash.from_xml(ret.body)
    assert ret_hash
    assert ret_hash.has_key?("firewall")
    assert ret_hash["firewall"].has_key?("use_firewall")
    assert_response :success
  end
  
  test "should update firewall" do
    put :create, DATA
    assert_equal 'Firewall settings have been written.', flash[:notice]
    assert_response :redirect
  end

end
