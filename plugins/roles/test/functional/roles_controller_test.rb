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

class RolesControllerTest < ActionController::TestCase


  def setup
    devise_sign_in
    #set fixtures, renew test files
    @test_path = File.join( Dir.tmpdir(), "webyast-roles-testsuite-tmpdir")
    `mkdir -p #{@test_path}`
    `cp #{File.join(File.dirname(__FILE__),'..','fixtures')}/* #{@test_path}`
    Role.const_set(:ROLES_DEF_PATH, File.join( @test_path, "roles.yml"))
    Role.const_set(:ROLES_ASSIGN_PATH, File.join( @test_path, "roles_assign.yml"))
    @model_class = Role
    #data for test update
    @data = {"role" => { "name" => "test", "users"=> [], "permissions" => []}}
    #stub DBus
    @dbus_obj = FakeDbus.new
    Permission.stubs(:dbus_obj).returns(@dbus_obj)
  end

  def teardown
    `rm -rf #{@test_path}`
  end

  def test_access_index_xml
    mime = Mime::XML
    get :index, :format => 'xml'
    assert_equal mime.to_s, @response.content_type
  end

  def test_access_index_json
    mime = Mime::JSON
    get :index, :format => 'json'
    assert_equal mime.to_s, @response.content_type
  end

  def test_update_noperm
    #ensure that nothing is saved
    @model_class.expects(:save).never

    @controller.stubs(:authorize!).raises(CanCan::AccessDenied.new());
    @data[:format] = 'xml'
    put :update, @data

    assert_response  403 # Forbidden
  end

  def test_index
    @request.accept = Mime::XML
    get :index, :format => 'xml'
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
    assert_response 400
  end

  def test_destroy
    @request.accept = Mime::XML
    post :destroy, :id => "test", :format => 'xml'
    assert_response 204
  end

  def test_create
    @request.accept = Mime::XML
    post :create, {:role => { :name => "role02._-test"}}, :format => 'xml'
    assert_response :success
  end

  def test_create_bad_name
    @request.accept = Mime::XML
    post :create, :name => "role02._-<dangerscript/>  test", :format => 'xml'
    assert_response 400
  end

  def test_update
    @request.accept = Mime::XML
    post :update, @data.merge(:id => "test"), :format => 'xml'
    assert_response :success
  end
end
