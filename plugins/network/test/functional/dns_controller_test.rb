#--
# Copyright (c) 2009 Novell, Inc.
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

class DnsControllerTest < ActionController::TestCase

  def setup
    @model_class = Dns
    @controller = Network::DnsController.new
    @request = ActionController::TestRequest.new
    @request.session[:account_id] = 1 # defined in fixtures
    stubs_functions # stubs actions defined in stubs.rb
  end  
  
  include PluginBasicTests 

  def test_content_of_xml
    get :show, :format => 'xml'
    h = Hash.from_xml @response.body
    assert_instance_of Array, h['dns']['nameservers']
    assert_instance_of Array, h['dns']['searches']
  end

  def test_update_without_info
    @model_class.any_instance.stubs(:save).returns true
    # had a bug with nil.split
    put :update, { "dns" => {} }
    assert_response :success
  end
end

