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
  def setup
    Rails.cache.clear
    @resource1 = Resource.new("interface1", {:cache_priority=>-10, :cache_enabled=>false, :singular=>true, :cache_arguments=>"", :controller => "resource1", :cache_reload_after=>0, :policy=>""})
    @resource2 = Resource.new("interface2", {:cache_priority=>-10, :cache_enabled=>false, :singular=>true, :cache_arguments=>"", :controller => "resource2", :cache_reload_after=>0, :policy=>""})

    Resource.stubs(:find).with(:all).returns([@resource1, @resource2])
    Resource.stubs(:find).with("interface1").returns(@resource1)
  end

  def test_all
    services = Resource.find(:all)
    assert_equal 2, services.size
    assert services.any? {|s| s.interface == "interface1"}
    assert services.to_xml
  end

  def test_find_and_link_to
    res = Resource.find "interface1"
    assert res
    assert_equal "/resource1", res.href
    assert res.to_xml
    assert res.to_json
  end
end
