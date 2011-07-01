#--
# Webyast Webservice framework
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
# test/functional/resources_controller_test.rb
#
# This tests proper returns for resource inspection
#

class TestPlugin
  attr_reader :directory
  def initialize path
    @directory = File.join(File.dirname(__FILE__), "..", path)
  end
end

unless defined? RESOURCE_REGISTRATION_TESTING
  RESOURCE_REGISTRATION_TESTING = true # prevent plugin registration in environment.rb
end
require File.join(File.dirname(__FILE__), "..", "test_helper")
require File.join(File.dirname(__FILE__), "..", "..", "lib", "resource_registration")

class ResourcesControllerTest < ActionController::TestCase

  def setup
    # set up test routing
    ResourceRegistration.reset
    plugin = TestPlugin.new "resource_fixtures/good"
    ResourceRegistration.register_plugin plugin
    ResourceRegistration.route ResourceRegistration.resources
  end
  
  test "resources access root" do
    get :index
    assert_response :success
  end
  
  test "resources show with interface" do
    get :show, :id => "org-opensuse-yast-modules-yapi-time"
    assert_response :success
  end
  
  test "resources show with unknown interface" do
    get :show, :id => "org-opensuse-yast-modules-yapi-bad-time"
    assert_response :missing
  end

  test "resources output xml format" do
    get :index, :format => "xml"
    assert_response :success
    assert @response.headers['Content-Type'] =~ %r{application/xml}
  end
  
  test "resources output html format" do
    get :index, :format => "html"
    assert_response :success
    assert @response.headers['Content-Type'] =~ %r{text/html}
  end
  
  test "resources by interfaces query" do
    ResourceRegistration.resources.each do |interface,implementations|
      get :show, "id" => interface.tr('.','-')
      assert_response :success
    end
  end  
  
end
