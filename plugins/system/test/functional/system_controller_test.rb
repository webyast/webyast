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
require 'test/unit'


class SystemControllerTest < ActionController::TestCase
  fixtures :accounts

  def setup
    @controller = SystemController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures

    @model = System.instance
    @model.stubs(:consolekit_power_management).with(:reboot).returns(true)
    @model.stubs(:consolekit_power_management).with(:shutdown).returns(true)

  end

  test "check 'show' result" do
    ret = get :show
    # success (200 OK)
    assert_response :success

    # is returned a valid XML?
    ret_hash = Hash.from_xml(ret.body)
    assert ret_hash
    # actions active value must be a boolean
    assert ret_hash['actions']['reboot'].has_key? 'active' and
	(ret_hash['actions']['reboot']['active'] == true or ret_hash['actions']['reboot']['active'] == false)
    assert ret_hash['actions']['shutdown'].has_key? 'active' and
	(ret_hash['actions']['shutdown']['active'] == true or ret_hash['actions']['shutdown']['active'] == false)
  end

  test "don't change status on error" do
    ret = get :show
    # success (200 OK)
    assert_response :success

    orig = Hash.from_xml(ret.body)

    put :update, :system => {:shutdown => {:active => true}, :zzzzzz => {}}
    assert_response :missing

    ret = get :show
    # success (200 OK)
    assert_response :success

    assert orig == Hash.from_xml(ret.body)
  end


  test "request reboot" do
    ret = put :update, :system => {:reboot => {:active => true}}
    assert_response :success

    # :reboot action must be active
    assert Hash.from_xml(ret.body)['actions']['reboot']['active']
  end

  test "request shutdown" do
    ret = put :update, :system => {:shutdown => {:active => true}}
    assert_response :success

    # :shutdown action must be active
    assert Hash.from_xml(ret.body)['actions']['shutdown']['active']
  end


  # test access rights

  test "return error when not logged in" do
    # remember the current setting
    session_backup = @request.session
    @request.session = {} # the session is not defined
    mime = Mime::XML
    ret = get :show, :format=>'xml'
    # expect 401 Unauthorized error code
    assert_response :unauthorized

    # revert back the original session setting (for the following tests)
    @request.session = session_backup
  end

  test "return error when not permitted" do
    @controller.stubs(:permission_check).raises(NoPermissionException.new("action", "test"))
    mime = Mime::XML
    ret = put :update, :system => {:reboot => {:active => true}}, :format=>'xml'
    # expect 403 Forbidden error code
    assert_response 403

    # set permissions back for the other tests
    @controller.stubs(:permission_check).returns(true);
  end


  # test invalid / malformed requests

  test "invalid (empty) request" do
    ret = put :update
    assert_response :missing
  end

  test "invalid (malformed) request" do
    ret = put :update, :zzzzzzz => :aaaaaaa
    assert_response :missing
  end

  test "invalid (empty actions) request" do
    ret = put :update, :system => {}
    assert_response :missing
  end

  test "invalid (unknown) request" do
    ret = put :update, :system => {:_invalid_action_ => {:active => true}}
    assert_response :missing
  end

  test "invalid (unexpected type) request" do
    ret = put :update, :system => {:reboot => :string}
    assert_response :missing
  end

  test "invalid (missing active parameter) request" do
    ret = put :update, :system => {:reboot => {}}
    assert_response :missing
  end

  test "invalid (non-boolean active parameter) request" do
    ret = put :update, :system => {:reboot => {:active => 'string'}}
    assert_response :missing
  end

  test "'reboot' not accpeted via GET" do
    ret = get :reboot

    # redirected to the control panel?
    assert_response :found
    assert_redirected_to :controller => :controlpanel, :action => :index

    # error reported?
    assert !ret.flash[:error].blank?
  end

  test "'shutdown' not accpeted via GET" do
    ret = get :shutdown

    # redirected to the control panel?
    assert_response :found
    assert_redirected_to :controller => :controlpanel, :action => :index

    # error reported?
    assert !ret.flash[:error].blank?
  end

  test "check 'shutdown' result" do
    ret = put :shutdown
    # redirected to the control panel?
    assert_response :found
    assert_redirected_to :controller => :logout

    # no error and a message present?
    assert ret.flash[:error].blank?
    assert !ret.flash[:message].blank?
  end

  test "check 'reboot' result" do
    ret = put :reboot

    # redirected to the control panel?
    assert_response :found
    assert_redirected_to :controller => :logout

    # no error and a message present?
    assert ret.flash[:error].blank?
    assert !ret.flash[:message].blank?
  end

  test "check 'shutdown' failed" do
    @model.stubs(:shutdown).returns(false)
    ret = put :shutdown

    # redirected to the control panel?
    assert_response :found
    assert_redirected_to :controller => :controlpanel, :action => :index

    # error reported?
    assert !ret.flash[:error].blank?
  end

  test "check 'reboot' failed" do
    @model.stubs(:reboot).returns(false)
    ret = put :reboot

    # redirected to the control panel?
    assert_response :found
    assert_redirected_to :controller => :controlpanel, :action => :index

    # error reported?
    assert !ret.flash[:error].blank?
  end


end

