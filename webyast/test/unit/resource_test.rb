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
# Tests for the Resource model
#
require File.join(File.dirname(__FILE__),"..", "test_helper")

class ResourceTest < ActiveSupport::TestCase
  TEST_RESOURCE_S = { :policy => "", :singular => true, :controller => "stest" }
  TEST_RESOURCE = { :policy => "own", :singular => false, :controller => "test" }
  REGISTERED_SERVICES = { "interface" => [TEST_RESOURCE], "sinterface" => [TEST_RESOURCE_S]}

  def setup
    ResourceRegistration.stubs(:resources).returns(REGISTERED_SERVICES)
  end

  def test_all
    services = Resource.find :all
    assert_equal 2, services.size
    assert services.any? {|s| s.interface == "interface"}
    assert services.to_xml
  end

  def test_find_and_link_to
    res = Resource.find "sinterface"
    assert res
    assert_equal "/stest", res.href
    assert res.to_xml
    assert res.to_json
  end
end
