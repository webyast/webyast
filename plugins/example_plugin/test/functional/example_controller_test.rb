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
#dbus stubbing
require File.expand_path( File.join("test","dbus_stub"), RailsParent.parent )

class ExampleControllerTest < ActionController::TestCase
  fixtures :accounts
  TEST_STRING="test"
  def setup    
    @controller = ExampleController.new
    @request = ActionController::TestRequest.new
    @request.session[:account_id] = 1 # defined in fixtures
    Example.any_instance.stubs(:load_content).returns("test")
    Example.stubs(:find).returns(Example.new)
    Example.any_instance.stubs(:update).returns(true)
  end
  
  def test_show
    get :show, :format => 'xml'
    assert_response :success
  end
  
  def test_update
    put :update, :format => 'xml', :example => { :content => TEST_STRING }
    assert_response :success
  end
end
