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
require "service"
require "yast_mock"
require "mocha"


class ServicesControllerTest < ActionController::TestCase
  
  def fixture(file)
    ret = open(File.join(File.dirname(__FILE__), "..", "fixtures", file)) { |f| YAML.load(f) }
    ret
  end


  def rights_enable(enable = true)
    if enable
      puts "*** FAKE PERMISSIONS FOR EXECUTE ***"
      ServicesController.any_instance.stubs(:yapi_perm_check).with("services.execute")
      ServicesController.any_instance.stubs(:yapi_perm_granted?).with("services.execute")
      
      puts "*** FAKE PERMISSIONS FOR READ ***"
      ServicesController.any_instance.stubs(:yapi_perm_check).with("services.read")
      ServicesController.any_instance.stubs(:yapi_perm_granted?).with("services.read")
    else
      puts "*** NO PERMISSIONS ***"
      @excpt =  NoPermissionException.new("org.opensuse.yast.modules.services.execute", "testuser")
      ServicesController.any_instance.stubs(:yapi_perm_check).with("services.execute").raises(@excpt)
      ServicesController.any_instance.stubs(:yapi_perm_granted?).with("services.execute").returns(false)
      
      ServicesController.any_instance.stubs(:yapi_perm_check).with("services.read").raises(@excpt)
      ServicesController.any_instance.stubs(:yapi_perm_granted?).with("services.read").returns(false)
    end
  end
  
  def init_data
    Service.stubs(:find).with(:all, {'read_status' => 1}).returns(@services)
  end
  
  def setup
    @controller = ServicesController.new
    @request = ActionController::TestRequest.new
    @request.session[:account_id] = 1 
    
    @services = fixture "services.yaml"
    @status = fixture "show_status.yaml"
    
    ServicesController.any_instance.stubs(:login_required)
  end
  
  
  def teardown
    puts "\n *** Teardown"
    ActiveResource::HttpMock.reset!
  end

  #first index call
  def test_index
    puts "\n *** Test index"
    
    init_data
    rights_enable
    get :index
    assert_response :success
    assert_valid_markup
    assert_not_nil assigns(:services)
  end
  
end
