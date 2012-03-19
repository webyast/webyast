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
require File.join(RailsParent.parent, "test","devise_helper")
require "service"

class ServicesControllerTest < ActionController::TestCase
  
  def fixture(file)
    ret = open(File.join(File.dirname(__FILE__), "..", "fixtures", file)) { |f| YAML.load(f) }
    ret
  end


  def rights_enable(enable = true)
    if enable
#      puts "*** FAKE PERMISSIONS FOR EXECUTE ***"
      ServicesController.any_instance.stubs(:yapi_perm_check).with("services.execute")
      ServicesController.any_instance.stubs(:yapi_perm_granted?).with("services.execute")
      
#      puts "*** FAKE PERMISSIONS FOR READ ***"
      ServicesController.any_instance.stubs(:yapi_perm_check).with("services.read")
      ServicesController.any_instance.stubs(:yapi_perm_granted?).with("services.read")
    else
#      puts "*** NO PERMISSIONS ***"
      @excpt =  NoPermissionException.new("org.opensuse.yast.modules.services.execute", "testuser")
      ServicesController.any_instance.stubs(:yapi_perm_check).with("services.execute").raises(@excpt)
      ServicesController.any_instance.stubs(:yapi_perm_granted?).with("services.execute").returns(false)
      
      ServicesController.any_instance.stubs(:yapi_perm_check).with("services.read").raises(@excpt)
      ServicesController.any_instance.stubs(:yapi_perm_granted?).with("services.read").returns(false)
    end
  end
  
  
  def init_data
    Service.stubs(:find).with(:all, {:read_status => 1}).returns(@services)
    Service.any_instance.stubs(:save).with({ :execute => 'stop', :custom => false}).returns({"stdout"=>"", "stderr"=>"", "exit"=>"0"})
  end
  
  def setup
    devise_sign_in
    @services = fixture "services.yaml"
    @status = fixture "show_status.yaml"
    @status_unknown = fixture "show_status_unknown.yaml"
    
    ServicesController.any_instance.stubs(:login_required)
  end
  
  # "TRUE" if service exist and "FALSE" for nonexistent service
  def service_exist(service)
    if service
      Service.any_instance.stubs(:read_status).with({"custom" => false}).returns(@status)
    else
      Service.any_instance.stubs(:read_status).with({"custom" => false}).returns(@status_unknown)
    end
  end

  
  test "access index html" do
    init_data
    rights_enable
    
    mime = Mime::HTML
    @request.accept = mime.to_s

    get :index, :format => "html"
    assert_response :success
# is in an endless loop
#    assert_valid_markup
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
    rights_enable
    service_exist(true)
    
    get :show_status, {:id => 'ntp', :custom => false}
    assert_response :success 
    assert_select 'span.status_not_running', :text => 'not running' #defined in fixture
  end
  
  test "get nonexistent service" do
    rights_enable
    service_exist(false)

    get :show_status, {:id => 'aaa', :custom => false}
    assert_response :success 
    assert_select 'span.status_unknown', :text => 'status unknown: 127'
  end

  test "test_execute" do
    init_data
    rights_enable
    
    get :execute, {:id => 'stop', :service_id => "ntp", :custom => false}
    assert_response :success 
    assert_select 'td.last', :text => 'success'
  end
end
