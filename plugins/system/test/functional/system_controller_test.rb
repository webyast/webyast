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


class SystemControllerTest < ActionController::TestCase

  def setup
    devise_sign_in
    @controller = SystemController.new
    @model = System.instance
    @model.stubs(:consolekit_power_management).with(:reboot).returns(true)
    @model.stubs(:consolekit_power_management).with(:shutdown).returns(true)

  end

  test "check show result" do
    mime = Mime::XML
    @request.accept = mime.to_s
    ret = get :show, :format => "xml"
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

  test "wrong or missing id" do
    mime = Mime::XML
    @request.accept = mime.to_s

    put :update, :format => "xml"
    assert_response :missing

    put :update, :id =>"not_valid", :format => "xml"
    assert_response :missing
  end


  test "request reboot" do
    mime = Mime::XML
    @request.accept = mime.to_s
    ret = put :update, :id =>"reboot", :format => "xml"
    assert_response :success

    # :reboot action must be active
    assert Hash.from_xml(ret.body)['actions']['reboot']['active']
  end

  test "request shutdown" do
    mime = Mime::XML
    @request.accept = mime.to_s
    ret = put :update, :id =>"shutdown", :format => "xml"
    assert_response :success

    # :shutdown action must be active
    assert Hash.from_xml(ret.body)['actions']['shutdown']['active']
  end


  # test access rights

  test "return error when not permitted" do
    @controller.stubs(:authorize!).raises(CanCan::AccessDenied.new())
    mime = Mime::XML
    ret = put :update, :id =>"shutdown", :format=>'xml'
    # expect 403 Forbidden error code
    assert_response 403

    # set permissions back for the other tests
    @controller.stubs(:authorize!).returns(true);
  end


  # test invalid / malformed requests

  test "reboot not accpeted via GET" do
    ret = get :reboot

    # redirected to the control panel?
    assert_response :found
    assert_redirected_to :controller => :controlpanel, :action => :index
    # error reported?
    assert !(ret.respond_to?('flash') && ret.flash[:error].blank?)
  end

  test "shutdown not accpeted via GET" do
    ret = get :shutdown

    # redirected to the control panel?
    assert_response :found
    assert_redirected_to :controller => :controlpanel, :action => :index

    # error reported?
    assert !(ret.respond_to?('flash') && ret.flash[:error].blank?)
  end

  test "check shutdown result" do
    ret = put :shutdown
    # redirected to the control panel?
    assert_response :found
    assert_redirected_to :controller => :accounts, :action => :sign_out

    # error reported?
    assert !(ret.respond_to?('flash') && ret.flash[:error].blank?)
  end

  test "check reboot result" do
    ret = put :reboot

    # redirected to the control panel?
    assert_response :found
    assert_redirected_to :controller => :accounts, :action => :sign_out

    # error reported?
    assert !(ret.respond_to?('flash') && ret.flash[:error].blank?)
  end

  test "check shutdown failed" do
    @model.stubs(:shutdown).returns(false)
    ret = put :shutdown

    # redirected to the control panel?
    assert_response :found
    assert_redirected_to :controller => :controlpanel, :action => :index

    # error reported?
    assert !(ret.respond_to?('flash') && ret.flash[:error].blank?)
  end

  test "check reboot failed" do
    @model.stubs(:reboot).returns(false)
    ret = put :reboot

    # redirected to the control panel?
    assert_response :found
    assert_redirected_to :controller => :controlpanel, :action => :index

    # error reported?
    assert !(ret.respond_to?('flash') && ret.flash[:error].blank?)
  end


end

