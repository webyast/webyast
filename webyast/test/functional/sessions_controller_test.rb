#--
# Webyast framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

#
# test/functional/sessions_controller_test.rb
#
#
require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class SessionsControllerTest < ActionController::TestCase
  fixtures :accounts

  def setup
    # Fake an active session
    # http://railsforum.com/viewtopic.php?id=1719
#    @request.session[:account_id] = 1 # defined in fixtures    
  end

  test "sessions new" do
    get :new, :format => 'xml'
    assert_response :success
  end
  
  test "sessions show" do
    get :show, :format => 'xml'
    assert_response :success
  end
  
  test "sessions create" do
    get :create, :format => 'xml'
    assert_response :success
  end
  
  test "sessions create with hash" do
    get :create, :format => 'xml', :hash => { "foo" => "bar" }
    assert_response :success
  end
  
  test "sessions create with login and password" do
    get :create, :format => 'xml', :hash => { :login => "test_user", :password => "test_password" }
    assert_response :success
  end
  
  test "sessions create fail with login and password" do
    get :create, :format => 'xml', :hash => { :login => "test_user", :password => "bad_password" }
    assert_response :success
  end
  
  test "sessions create fail with brute force protection" do
    BruteForceProtection.any_instance.stubs(:blocked?).returns(true)
    get :create, :format => 'xml', :hash => { :login => "test_user", :password => "bad_password" }
    assert_response :success
  end

  test "sessions create remember_me" do
    @request.session[:account_id] = 1 # defined in fixtures
    get :create, :format => 'xml', :remember_me => true
# FIXME   assert cookies[:auth_token]
    assert_response :success
  end
  
  test "sessions destroy" do
    get :destroy, :format => 'xml'
    assert_response :success
  end
  
  test "output xml format" do
    get :show, :format => "xml"
    assert_response :success
    assert @response.headers['Content-Type'] =~ %r{application/xml}
  end
  
  test "output html format" do
    get :show, :format => "html"
    assert_response :redirect
    assert @response.headers['Content-Type'] =~ %r{text/html}
  end
  
end
