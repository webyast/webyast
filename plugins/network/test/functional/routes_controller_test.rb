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
require File.expand_path(File.dirname(__FILE__) + "/stubs.rb")
require 'route'

class RoutesControllerTest < ActionController::TestCase

  # fixtures for update test
  DATA_GOOD_UI = {"routes" => { "id" => "default", "via" => "10.7.7.7"}, "id"=>"default"}
  DATA_GOOD_DOC = {"route" => { "id" => "default", "via" => "10.7.7.7"}, "id"=>"default"}
  DATA_BAD = {"routes"=>{"id"=>"default", "via"=>"10.20.30"}, "id"=>"default"}


  def setup
    YastService.expects(:Call).never
    @model_class = Route
    @controller = Network::RoutesController.new
    @request = ActionController::TestRequest.new
    @request.session[:account_id] = 1 # defined in fixtures
    
    stubs_functions # stubs actions defined in stubs.rb
  end  

#  include CollectionResourceTests ??????????????????????????????????

  def test_show_xml
    get :show, :format => 'xml', :id => 'default'
    h = Hash.from_xml @response.body
    assert_instance_of String, h["routes"]["via"]
  end

  def test_index_xml
    get :index, :format => 'xml'
    h = Hash.from_xml @response.body
    assert_instance_of Hash, h["routes"]
    assert_equal "default", h["routes"]["default"]["id"]
  end

  def test_valid_update_as_sent_by_ui
    put :update, DATA_GOOD_UI
    assert_response 200
  end

  def test_valid_update_as_documented
    put :update, DATA_GOOD_DOC
    assert_response 200
  end

  
  # Validation test: ensure that nothing is saved 
  # Raised resource Invalid exception - #<InvalidParameters: Invalid arguments: {:via=>:invalid}>
  
  def test_validation
    @model_class.expects(:save).never
    put :update, DATA_BAD
    assert_response 422
  end
end

