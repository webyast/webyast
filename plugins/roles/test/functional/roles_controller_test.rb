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
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class RolesControllerTest < ActionController::TestCase
  fixtures :accounts

  def setup
    #set fixtures, renew test files
		@test_path = File.join( Dir.tmpdir(), "webyast-roles-testsuite-tmpdir")
    `mkdir -p #{@test_path}`
		`cp #{File.join(File.dirname(__FILE__),'..','fixtures')}/* #{@test_path}`
    Role.const_set(:ROLES_DEF_PATH, File.join( @test_path, "roles.yml"))
    Role.const_set(:ROLES_ASSIGN_PATH, File.join( @test_path, "roles_assign.yml"))
    @model_class = Role
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
#data for test update
    @data = {"roles" => { "name" => "test", "roles"=> [], "permissions" => []}}
#stub DBus
		@dbus_obj = FakeDbus.new
		Permission.stubs(:dbus_obj).returns(@dbus_obj)
  end

  include CollectionResourceTests

  def teardown
    `rm -rf #{@test_path}`
  end

  def test_index
    get :index
    assert_response :success
    h=Hash.from_xml @response.body
    assert_equal 3, h['roles'].size
  end

  def test_show
    get :show, :format => 'xml', :id => "test"
    assert_response :success
    h=Hash.from_xml @response.body
    assert_equal 3,h['role']['users'].size
  end

  def test_show_nonexist
    get :show, :format => 'xml', :id => "nonexist"
    assert_response 422
  end

  def test_destroy
    post :destroy, :id => "test"
    assert_response :success
    h=Hash.from_xml @response.body
    assert_equal 2, h['roles'].size
  end

  def test_create
    post :create, "roles" => { "name" => "role02._-  test"}
    assert_response :success
  end

  def test_create_bad_name
    post :create, "roles" => { "name" => "role02._-<dangerscript/>  test"}
    assert_response 422
  end

  def test_update
    post :update, @data.merge(:id => "test")
    assert_response :success
  end
end
