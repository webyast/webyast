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

# = PluginBasicTests module
# The module is designed to perform few basic tests of WebYaST plugin
# controller behavior. Its goal is provide same unify behavior to each
# WebYaST plugin like unified response if user doesn't have permissions
# or same content type.
# == Prerequisites
# The module expect some hints from controller test file for correct work.
# It needs model class specified at @*model_class* field, controller instance at
# @*controller* and request specification at @*request* field. Field @*data* is
# used to test update with valid data but without permissions.
# Controller is expected to be thin layer and all dbus or system call is done
# at model code. Controller use during reading only *find* metode of model
# and during writing only *save* method.
# == Example usage
# This example show basic testing of controller of plugin
#    require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
#    require 'test/unit'
#    require 'mocha'
#    require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )
#
#    class LanguageControllerTest < ActionController::TestCase
#      fixtures :accounts
#      
#        TEST_DATA = {:language => {
#      :current => "cs_CZ",
#      :utf8 => "true",
#      :rootlocale => "false"
#    }}
#      def setup
#        @model_class = Language
#        @controller = LanguageController.new
#        @request = ActionController::TestRequest.new
#        # http://railsforum.com/viewtopic.php?id=1719
#        @request.session[:account_id] = 1 # defined in fixtures
#        @data = TEST_DATA
#      end
#
#      include PluginBasicTests
#      #another specific controller test like correct parsing arguments
#      #or specific exceptions
#     end

# TODO use better names (aliased for compatibility),
# PluginBasicTests -> SingleResourceTests

module CommonResourceTests
  # A parameter hash that contains :id => "test" for the collection tests
  # and nothing for the singleton tests, so that routing works for both cases.
  def just_id
    raise NotImplementedError
  end

  def test_update_noparams
    @model_class.stubs(:save)
    put :update, just_id
    assert_response 422
  end

  def test_update_noperm
    #ensure that nothing is saved
    @model_class.expects(:save).never
    @controller.stubs(:authorize!).raises(CanCan::AccessDenied.new());
    mime = Mime::XML
    @data[:format] = 'xml' if @data
    put :update, just_id.merge(@data || {:format => 'xml'})

    assert_response  403 # Forbidden
  end

end

module PluginBasicTests
  include CommonResourceTests

  def just_id
    Hash.new                    # no :id
  end

  def test_access_denied_xml
    #mock model to test only controller
    @model_class.stubs(:find)
    @controller.stubs(:authorize!).raises(CanCan::AccessDenied.new());
    mime = Mime::XML
    get :show, :format => 'xml'
    assert_response 403 # Forbidden
  end

  def test_access_denied
    #mock model to test only controller
    @model_class.stubs(:find)
    @controller.stubs(:authorize!).raises(CanCan::AccessDenied.new());
    get :show
    assert_response 302 # Forbidden
  end

  def test_access_show_xml
    mime = Mime::XML
    get :show, :format => 'xml'
    assert_equal mime.to_s, @response.content_type
  end

  def test_access_show_json
    mime = Mime::JSON
    get :show, :format => 'json'
    assert_equal mime.to_s, @response.content_type
  end
end

module CollectionResourceTests
  include CommonResourceTests

  def just_id
    { :id => "test" }
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
end
