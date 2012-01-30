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

#
# test/functional/resource_route_test.rb
#
# This tests route creation from the resource database
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

class ResourceRouteTest < ActiveSupport::TestCase
  setup do
    @account = Factory(:account)
    sign_in @account
  end

  test "resource route initialization" do

    plugin = TestPlugin.new "resource_fixtures/good"
    ResourceRegistration.reset
    ResourceRegistration.register_plugin plugin
    ResourceRegistration.route ResourceRegistration.resources
#    $stderr.puts ActionController::Routing::Routes.routes
    # root URI links to main
    assert_recognizes( { :controller => "main", :action => "index" }, "/" )
    # as does /resources
    assert_routing( { :path => "/resources", :method => :get }, { :controller => "resources", :action => "index" } )

    # Ensure there is a route for every resource
    ResourceRegistration.resources.each do |interface,implementations|
      implementations.each do |implementation|
        assert_generates "#{implementation[:controller]}", { :controller => "#{implementation[:controller]}", :action => :index }
      end
    end
  end

end
