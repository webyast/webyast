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


class PatchesControllerTest < ActionController::TestCase

  def setup
    devise_sign_in
    # we make them member variables so we can use
    # in other assertions
    @p1 = Patch.new(
            :resolvable_id => "462",
            :name => "softwaremgmt",
            :kind => "important",
            :summary => "Various fixes for the software management stack",
            :arch => "noarch",
            :repo => "openSUSE-11.1-Updates")

    @p2 = Patch.new(
            :resolvable_id => "463",
            :name => "yast",
            :kind => "security",
            :summary => "Various fixes",
            :arch => "noarch",
            :repo => "openSUSE-11.1-Updates")

    Patch.stubs(:mtime).returns(Time.now)
    Patch.stubs(:find).with(:all).returns([@p1, @p2])
    Patch.stubs(:find).with('462').returns(@p1)
    Patch.stubs(:find).with('wrong_id').returns(nil)
    Patch.stubs(:find).with('not_found').returns(nil)

    @p1.stubs(:install).returns(true)
  end

  def teardown
    Mocha::Mockery.instance.stubba.unstub_all
  end
  
  test "access index" do
    get :index
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

  test "access show xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :show, :id =>"462"
    assert_equal mime.to_s, @response.content_type
    assert_response :success
  end
  
  test "access show json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :show, :id =>"462"
    assert_equal mime.to_s, @response.content_type
  end

  test "access show with wrong id" do
    get :show, :id =>"not_found"
    assert_response 404
  end

  test "installing a patch" do
    mime = Mime::XML
    @request.accept = mime.to_s
    post :install, :format => :xml, :id =>"462"
    assert_response :success
  end

  test "installing a patch with wrong ID" do
    mime = Mime::XML
    @request.accept = mime.to_s
    post :install, :format => :xml, :id =>"wrong_id"
    assert_response :success #does not return an error cause the patch has already been 
                             #installed before
  end

  test "read patch messages" do
    # simulate a message in the messages file
    msg = 'Patch message'
    PatchesController.any_instance.stubs(:read_messages).returns([{:message => msg}])
    mime = Mime::XML
    @request.accept = mime.to_s
    get :index, :messages => true
    assert_response :success
    # check the content
    assert Hash.from_xml(@response.body)["messages"][0]["message"] == msg
  end

  test "no patch message" do
    # simulate non-existing messages file
    PatchesController.any_instance.stubs(:read_messages).returns([])
    mime = Mime::XML
    @request.accept = mime.to_s
    get :index, :messages => true
    assert_response :success
    # no message
    assert Hash.from_xml(@response.body)["messages"].empty?
  end

  test "license required" do
    PatchesState.stubs(:read).returns(:message_id => "PATCH_EULA").once
    get :index
    assert_redirected_to :action => "license"
  end

  test "license required XML" do
    PatchesState.stubs(:read).returns(:message_id => "PATCH_EULA").once
    mime = Mime::XML
    @request.accept = mime.to_s

    get :index
    assert_response :success
    assert_equal "PACKAGEKIT_LICENSE", Hash.from_xml(@response.body)["error"]["type"]
  end

  test "license required JSON" do
    PatchesState.stubs(:read).returns(:message_id => "PATCH_EULA").once
    mime = Mime::JSON
    @request.accept = mime.to_s

    get :index
    assert_response :success
    # TODO in Ruby 1.9 we could use JSON from stdlib to parse the string
    assert_match /license confirmation/, @response.body
  end

  def test_show_license
    get :license
    assert_response :success
  end

  test "patch installation in progress" do
    # 42 patches to install
    Patch.stubs(:installing).returns([true, 42])

    get :index
    assert_response :success
    assert_match /There are 42 patches to install/, @response.body
  end

  test "patch installation in progress XML" do
    # 42 patches to install
    Patch.stubs(:installing).returns([true, 42])
    mime = Mime::XML
    @request.accept = mime.to_s

    get :index
    assert_response :success
    error = Hash.from_xml(@response.body)["error"]
    assert_equal 42, error["count"]
    assert_match /42 patches remain to install/, error["description"]
  end

  test "patch installation in progress JSON" do
    # 42 patches to install
    Patch.stubs(:installing).returns([true, 42])
    mime = Mime::JSON
    @request.accept = mime.to_s

    get :index
    assert_response :success
    # TODO in Ruby 1.9 we could use JSON from stdlib to parse the string
    assert_match /42 patches remain to install/, @response.body
  end

end
