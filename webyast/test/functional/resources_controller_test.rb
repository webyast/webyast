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

require File.join(File.dirname(__FILE__), "..", "test_helper")
require File.dirname(__FILE__) + '/../devise_helper'

class ResourcesControllerTest < ActionController::TestCase
  def setup
    devise_sign_in
    @resource1 = Resource.new("org.interface1.plugin", {:cache_priority=>-10, :cache_enabled=>false, :singular=>true, :cache_arguments=>"", :controller => "resource1", :cache_reload_after=>0 })
    @resource2 = Resource.new("org.interface2.plugin", {:cache_priority=>-10, :cache_enabled=>false, :singular=>true, :cache_arguments=>"", :controller => "resource2", :cache_reload_after=>0 })
    Resource.stubs(:find).with(:all).returns [@resource1, @resource2]
    Resource.stubs(:find).with('org.interface1.plugin').returns @resource1
    Resource.stubs(:find).with('org.test.plugin').returns nil
  end

  test "resources access root" do
    get :index
    assert_response :success
  end

  test "resources show with interface" do
    get :show, :id => "org.interface1.plugin"
    assert_response :success
  end

  test "resources show with unknown interface" do
    get :show, :id => "org.test.plugin"
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

end
