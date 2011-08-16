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
require 'hostname'

class HostnameControllerTest < ActionController::TestCase

  DATA_GOOD = {"hostname" => {"name" => "foo", "domain" => "bar"}}
  DATA_BAD = {"hostname" => {"name" => ">weird\\characters"}}
  
  def setup
    @model_class = Hostname
    @controller = Network::HostnameController.new
    @request = ActionController::TestRequest.new
    @request.session[:account_id] = 1 # defined in fixtures
    
    stubs_functions # stubs actions defined in stubs.rb
  end  
  
  include PluginBasicTests

  def test_content_of_xml
    get :show, :format => 'xml'
    h=Hash.from_xml @response.body
    assert_equal 'testhost', h['hostname']['name']
    assert_equal 'suse.de', h['hostname']['domain']
  end

  def test_valid_update
    @model_class.any_instance.stubs(:save).returns true
    put :update, DATA_GOOD
    assert_response 200
  end

  def test_validation
    #ensure that nothing is saved
    @model_class.expects(:save).never
    put :update, DATA_BAD
    assert_response 422
  end
end

