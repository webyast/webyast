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

class RepositoriesControllerTest < ActionController::TestCase
  def setup
    devise_sign_in

    @r1 = Repository.new("factory-oss", "FACTORY-OSS", true)
    @r2 = Repository.new("factory-non-oss", "FACTORY-NON-OSS", false)

    Repository.stubs(:find).with(:all).returns([@r1, @r2])
    Repository.stubs(:find).with('factory-oss').returns([@r1])
    Repository.stubs(:find).with('none').returns([])

    @repo_opts = {:id => 'repo-oss', :name => 'name',
      :url => 'http://example.com', :priority => 99, :keep_packages => false,
      :enabled => true, :autorefresh => true
    }
  end
  
  test "access index" do
    get :index
    assert_response :success
#    assert_valid_markup
    assert_not_nil assigns(:repos)
    assert flash.empty?
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
    get :show, :id =>"factory-oss"
    assert_equal mime.to_s, @response.content_type
    assert_response :success
  end

  test "access show json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :show, :id =>"factory-oss"
    assert_equal mime.to_s, @response.content_type
  end

  test "access repo with wrong id" do
    get :show, :id =>"none"
    assert_response :missing
  end


  test "index - dbus_exception" do
    msg_err = DBus::Message.new(DBus::Message::ERROR)
    msg_err.error_name = 'DBus error'

    Repository.stubs(:find).raises(DBus::Error, msg_err)
    mime = Mime::XML
    @request.accept = mime.to_s

    get :index, :format => :xml
    assert_response :missing
  end

  test "show - dbus_exception" do
    msg_err = DBus::Message.new(DBus::Message::ERROR)
    msg_err.error_name = 'DBus error'

    Repository.stubs(:find).raises(DBus::Error, msg_err)

    get :show, :id => "factory-oss"
    assert_response :missing
  end

  test "update" do
    Repository.any_instance.stubs(:update).returns(true)
    mime = Mime::XML
    @request.accept = mime.to_s
    put :update, :format => :xml, :id => "factory-oss", :repository => @repo_opts
    assert_response :success
  end

  test "update - save failed" do
    Repository.any_instance.expects(:update).returns(false)
    mime = Mime::XML
    @request.accept = mime.to_s
    put :update, :format => :xml, :id => "factory-oss", :repository => @repo_opts
    assert_response :missing
  end

  test "update empty parameters" do
    Repository.any_instance.expects(:update).never
    put :update, :id => "factory-oss", :repository => {}
    assert_response 422
  end

  test "create html" do
    Repository.any_instance.expects(:update).returns(true)
    put :create, :id => "factory-oss", :repository => @repo_opts
#    assert_valid_markup
    assert flash[:message] == "Repository 'name' has been updated."
    assert_response :redirect 
  end


  test "create xml" do
    Repository.any_instance.expects(:update).returns(true)
    mime = Mime::XML
    @request.accept = mime.to_s
    put :create, :format => :xml, :id => "factory-oss", :repository => @repo_opts
    assert_response :success
  end

  test "create empty parameters" do
    Repository.any_instance.expects(:update).never
    put :create, :id => "factory-oss", :repository => {}
    assert_response 422
  end

  test "create save failed" do
    Repository.any_instance.expects(:update).returns(false)
    mime = Mime::XML
    @request.accept = mime.to_s
    put :create, :format => :xml, :id => "factory-oss", :repository => @repo_opts
    assert_response :missing
  end

  test "destroy failed" do
    Repository.any_instance.expects(:destroy)
    mime = Mime::XML
    @request.accept = mime.to_s
    post :destroy, :format => :xml, :id => "factory-oss"
    assert_response :missing
  end

  test "destroy success" do
    Repository.any_instance.expects(:destroy)
    # the first find is successful, the second (after removal) is empty
    Repository.stubs(:find).with('factory-oss').returns([@r1]).then.returns([])
    mime = Mime::XML
    @request.accept = mime.to_s
    post :destroy, :format => :xml, :id => "factory-oss"
    assert_response :success
  end

  test "destroy non-existing repo" do
    Repository.any_instance.expects(:destroy).never
    mime = Mime::XML
    @request.accept = mime.to_s
    post :destroy, :format => :xml, :id => "none"
    assert_response :missing
  end

  # Test Dbus exception handling
  test "update - dbus_exception" do

    msg_err = DBus::Message.new(DBus::Message::ERROR)
    msg_err.error_name = 'DBus error'

    Repository.any_instance.stubs(:update).raises(DBus::Error, msg_err)
    mime = Mime::XML
    @request.accept = mime.to_s
    put :update, :format => :xml, :id => "factory-oss", :repository => @repo_opts
    assert_response :missing
  end

  test "create - dbus_exception" do

    msg_err = DBus::Message.new(DBus::Message::ERROR)
    msg_err.error_name = 'DBus error'

    Repository.any_instance.stubs(:update).raises(DBus::Error, msg_err)
    mime = Mime::XML
    @request.accept = mime.to_s
    post :create, :format => :xml, :id => "factory-oss", :repository => @repo_opts
    assert_response :missing
  end

  test "destroy - dbus_exception in find" do

    msg_err = DBus::Message.new(DBus::Message::ERROR)
    msg_err.error_name = 'DBus error'

    Repository.stubs(:find).raises(DBus::Error, msg_err)
    mime = Mime::XML
    @request.accept = mime.to_s

    post :destroy, :format => :xml, :id => "factory-oss"
    assert_response :missing
  end

   test "destroy - dbus_exception in destroy" do

    msg_err = DBus::Message.new(DBus::Message::ERROR)
    msg_err.error_name = 'DBus error'

    Repository.any_instance.stubs(:destroy).raises(DBus::Error, msg_err)
    mime = Mime::XML
    @request.accept = mime.to_s

    post :destroy, :format => :xml, :id => "factory-oss"
    assert_response :missing
  end

  # Test validations
  test "create with invalid priority" do
    Repository.any_instance.expects(:update).never

    r = @repo_opts
    r[:priority] = 'assdfdsf'
    mime = Mime::XML
    @request.accept = mime.to_s
    put :create, :format => :xml, :id => "factory-oss", :repository => r
    assert_response 422
  end

  test "create with too low priority" do
    Repository.any_instance.expects(:update).never

    r = @repo_opts
    r[:priority] = -20
    mime = Mime::XML
    @request.accept = mime.to_s
    put :create, :format => :xml, :id => "factory-oss", :repository => r
    assert_response 422
  end

  test "create with too high priority" do
    Repository.any_instance.expects(:update).never

    r = @repo_opts
    r[:priority] = 2000

    put :create, :id => "factory-oss", :repository => r
    assert_response 422
  end

  test "create with empty url" do
    Repository.any_instance.expects(:update).never

    r = @repo_opts
    r[:url] = ''

    put :create, :id => "factory-oss", :repository => r
    assert_response 422
  end

  test "create with empty id" do
    Repository.any_instance.expects(:update).never

    r = @repo_opts
    r[:id] = ''

    put :create, :id => '', :repository => r
    assert_response 422
  end

  test "create with invalid enabled" do
    Repository.any_instance.expects(:update).never

    r = @repo_opts
    r[:enabled] = 'asdsad'

    put :create, :id => 'factory-oss', :repository => r
    assert_response 422
  end

  test "create with invalid keep_packages" do
    Repository.any_instance.expects(:update).never

    r = @repo_opts
    r[:keep_packages] = 'asdsad'

    put :create, :id => 'factory-oss', :repository => r
    assert_response 422
  end

  test "create with invalid autorefresh" do
    Repository.any_instance.expects(:update).never

    r = @repo_opts
    r[:autorefresh] = 'asdsad'
    mime = Mime::XML
    @request.accept = mime.to_s
    put :create, :format => :xml, :id => 'factory-oss', :repository => r

    assert_response 422
  end

end
