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
require 'test/unit'
require 'mocha'


class UsersControllerTest < ActionController::TestCase
  def setup
    devise_sign_in
    User.stubs(:find_all).returns([])
  end

  test "access index" do
    mime = Mime::HTML
    @request.accept = mime.to_s
    get :index
    assert_valid_markup
    assert_response :success
  end

  test "access index xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :index
    assert_equal mime.to_s, @response.content_type
  end

  test "access index json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :index
    assert_equal mime.to_s, @response.content_type
  end

  def test_users_index_no_groupsget_permission
    UsersController.any_instance.stubs(:authorize!).raises(CanCan::AccessDenied.new());
    get :index
    assert !flash.empty?
    assert_response  302 # Forbidden
  end


  test "access show" do
    mime = Mime::HTML
    @request.accept = mime.to_s

    u = User.new
    u.load_attributes({:uid => "schubi5"})
    User.stubs(:find).with("schubi5").returns(u)
    get :show, :format => "html", :id => "schubi5"
    assert_response :success
  end

  test "access show with wrong user" do
    User.stubs(:find).with("schubi_not_found").returns(nil)
    get :show, :id => "schubi_not_found"
    assert_response 404
  end

  def test_update_user
   u = User.new
   u.load_attributes({:uid => "schubi5"})
   User.stubs(:find).with("schubi5").returns(u)
   User.stubs(:find_all).returns(u)
   User.any_instance.stubs(:save).with("schubi5").returns(true)

   post :update, {:user => { :id => "schubi5", :cn => "schubi5" }}
   assert !flash.empty?
   assert_response 302
  end


end
