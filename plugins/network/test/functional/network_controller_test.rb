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
require File.expand_path(File.dirname(__FILE__) + "/stubs.rb")

require "interface"
require "hostname"
require "dns"
require "route"
require "mocha"

class NetworkControllerTest < ActionController::TestCase
  
  def setup
    devise_sign_in
    NetworkController.any_instance.stubs(:login_required)
    stubs_functions # stubs actions defined in stubs.rb
  end
  
  test "access index html" do
    mime = Mime::HTML
    @request.accept = mime.to_s

    get :index, :format => "html"
    assert_response :success
    assert_valid_markup
    assert_equal mime.to_s, @response.content_type
  end

  def test_should_show_it
    get :index
    assert_response :success
    assert_valid_markup

    assert_not_nil assigns(:default_route)
    assert_not_nil assigns(:name)
  end

  def test_with_dhcp
    get :index, :interface => "eth1"
    assert_response :success
    assert_valid_markup

    assert_not_nil assigns(:default_route)
    assert_not_nil assigns(:name)
  end

  def test_dhcp_without_change
    put :update, { :interface => "eth1", :conf_mode => "dhcp", :default_route => "192.168.1.1", :nameservers => "192.168.1.2 192.168.1.42", :searchdomains => "labs.example.com example.com", :hostname => "arthur", :domain => "britons" }
    assert_response :redirect
    assert_redirected_to :controller => "controlpanel", :action => "index"
  end

end
