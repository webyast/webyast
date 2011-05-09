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
require 'route'

class RoutesControllerTest < ActionController::TestCase

  def setup
    YastService.expects(:Call).never
    @model_class = Route
    d = Route.new({"id" => "default", "via" => "42.42.42.42"})
    Route.stubs(:find).with("default").returns(d)
    Route.stubs(:find).with(:all).returns({"default" => d})
    @controller = Network::RoutesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end  

  include CollectionResourceTests

  def test_show_xml
    get :show, :format => 'xml', :id => 'default'
    h = Hash.from_xml @response.body
    assert_instance_of String, h['route']['via']
  end

  def test_index_xml
    get :index, :format => 'xml'
    h = Hash.from_xml @response.body
   
    assert_instance_of Hash, h["routes"]
    #assert_instance_of Array, h["routes"]
    assert_equal "default", h["routes"]["default"]["id"]
    #assert_equal "default",  h["routes"][0]["id"]
  end

  DATA_GOOD_UI = {
    "routes" => {
      "id" => "default",
      "via" => "10.7.7.7"
    },
    "id"=>"default"
  }
  DATA_GOOD_DOC = {
    "route" => {
      "id" => "default",
      "via" => "10.7.7.7"
    },
    "id"=>"default"
  }
  DATA_BAD = {"routes"=>{
      "id"=>"default",
      "via"=>"10.20.30"
	 },
      "id"=>"default"
     }

  def test_valid_update_as_sent_by_ui
    @model_class.any_instance.stubs(:save).returns true
    put :update, DATA_GOOD_UI
    assert_response 200
  end

  def test_valid_update_as_documented
    @model_class.any_instance.stubs(:save).returns true
    put :update, DATA_GOOD_DOC
    assert_response 200
  end

  def test_validation
    #ensure that nothing is saved
    @model_class.expects(:save).never
    put :update, DATA_BAD
    assert_response 422
  end
end

