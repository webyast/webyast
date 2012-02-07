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

class ActivedirectoryControllerTest < ActionController::TestCase
  ACTIVEDIRECTORY = { "create_dirs" => "0", "enabled" => "false", "domain" => "AD.SUSE.DE" }
  PARAMS = { "activedirectory"=> {"domain"=>"AD.SUSE.DE", "enabled"=>"false"}}
  
  def setup
    devise_sign_in
    Activedirectory.stubs(:find).returns(Activedirectory.new(ACTIVEDIRECTORY))
    Activedirectory.any_instance.stubs(:save).returns(true)
  end
  
  include PluginBasicTests
  
  test "access index html" do
    mime = Mime::HTML
    @request.accept = mime.to_s

    get :index, :format => "html"
    assert_response :success
    assert_valid_markup
    assert_equal mime.to_s, @response.content_type
  end
  
  test "access index xml" do
    mime = Mime::XML
    @request.accept = mime.to_s

    xml = get :show, :format => "xml"
    xml_to_hash = Hash.from_xml(xml.body)
    
    assert xml_to_hash
    assert xml_to_hash.has_key?("activedirectory")
    
    assert_response :success
    assert_equal mime.to_s, @response.content_type
  end
  
  test "should update ActiveDirectory" do
    put :update, PARAMS
    assert_response :redirect
    assert_equal "Active Directory client configuraton successfully written.", flash[:message]
    assert_redirected_to :controller => "controlpanel", :action => "index"
  end

end
