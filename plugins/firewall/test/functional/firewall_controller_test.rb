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

class FirewallControllerTest < ActionController::TestCase
  fixtures :accounts
  
  DATA = { "firewall_service:mysql"=>"true", 
         "firewall_service:apache2"=>"true", 
         "firewall"=>{"use_firewall"=>"false"}
       }
  OK_RESULT = {"saved_ok" => true, "error" => ""}
  
  def setup
    @model_class = Firewall
    Firewall.stubs(:permission_check)
    @controller = FirewallController.new
    @request = ActionController::TestRequest.new
    @request.session[:account_id] = 1 # defined in fixtures
  end
  
# magic for auto tests  is currently "Disabled"
# include PluginBasicTests

#ERRORS: 
#1) Uncaught exception Mocha::ExpectationError: unexpected invocation: YastService.Call('YaPI::FIREWALL::Read') unsatisfied expectations:
#2) No permission: org.opensuse.yast.module-manager.import for vlewin

  test "should get index" do
    Rails.logger.debug "\n*** TEST SHOULD GET INDEX ***"
    get :index
    assert_response :success
  end
  
   test "should get show" do
    Rails.logger.debug "\n*** TEST SHOULD GET SHOW ***"
    ret = get :show, :format => "xml"
    ret_hash = Hash.from_xml(ret.body)
    assert ret_hash
    assert ret_hash.has_key?("firewall")
    assert ret_hash["firewall"].has_key?("use_firewall")
    assert_response :success

  end
  
  test "should update firewall" do
    Rails.logger.debug "\n*** TEST SHOULD UPDATE FIREWALL ***"
    mock_save
    put :update, DATA
    assert_equal 'Firewall settings have been written.', flash[:notice]
    assert_response :redirect
  end
  
  def mock_save
    YastService.stubs(:Call).with( "YaPI::FIREWALL::Write", Firewall.toVariantASV(DATA)).once.returns(OK_RESULT)
    Firewall.stubs(:permission_check)
  end
end

#  include PluginBasicTests

#  def test_update
#    mock_save
#    put :update, UPDATE_DATA
#    assert_response :success
#  end

#  def test_create
#    mock_save
#    put :create, UPDATE_DATA
#    assert_response :success
#  end

  
#end
