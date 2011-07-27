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
    Service.stubs(:find).with(:all, {:read_status => 1}).returns(@services)
    Service.any_instance.stubs(:read_status).with({"custom" => false}).returns(@status)
    
    

    Service.any_instance.stubs(:read_status).with({"custom" => false}).returns(@status)
#    read_status('action' => 'show', 'id' => 'ntp', 'custom' => false, 'controller' => 'services')
  end
  
  def setup
    @controller = ServicesController.new
    @request = ActionController::TestRequest.new
    @request.session[:account_id] = 1 
    
    @services = fixture "services.yaml"
    @status = fixture "show_status.yaml"
    
    ServicesController.any_instance.stubs(:login_required)
  end
  
  
  test "access index html" do
    init_data
    rights_enable
    
    mime = Mime::HTML
    @request.accept = mime.to_s

    get :index, :format => "html"
    assert_response :success
    assert_valid_markup
    assert_equal mime.to_s, @response.content_type
  end
  
  test "access index xml" do
    init_data
    rights_enable
    
    mime = Mime::XML
    @request.accept = mime.to_s
    get :index, :format => "xml"
    assert_response :success
    assert_equal mime.to_s, @response.content_type
  end
  
  test "access index json" do
    init_data
    rights_enable
    
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :index, :format => "json"
    assert_response :success
    assert_equal mime.to_s, @response.content_type
  end  

  test "get ntp status" do
    init_data
    rights_enable

    ret = get :show_status, {:id => 'ntp', :custom => false}
    assert_response :success
    assert_valid_markup
    assert !ret.body.index("not running").nil? # fixture status is 3 = not running
  end
  
  test "get nonexistent service" do
    init_data
    rights_enable
    
    ret = get :show_status, {:id => 'aaa', :custom => false}
    assert_response :success
    puts ret.body
    
    #??????????
#    assert_equal ret.body.index("cannot read status")
  end

#  ????????????????????????????????????
#  def test_ntp_status
#    init_data
#    rights_enable
#    
#    service = Service.new('ntp')
#    @response = service.read_status({"custom" => false})
#    puts @response.inspect
#    assert @response.status == 3
#  end
  
  

#  def test_execute
#    put :execute, { :service_id => 'ntp', :id => 'stop', :custom => false}
#    assert assigns(:error_string), "success"
#    assert assigns(:result_string), "Shutting down network time protocol daemon (NTPD)\n"
#  end
end
