#--
# Copyright (c) 2009-2010 Novell, Inc.
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
require 'test/unit'
require 'license'
require 'mocha'

class EulasControllerTest < ActionController::TestCase
  YAML_CONTENT = <<EOF
licenses:
  - openSUSE-11.1
  - SLES-11
EOF

  UPDATE_DATA = {"id"=>"1", 
                 "format"=>"xml",
                 "eulas"=>{"name"    =>"openSUSE-11.1", 
                           "id"      =>"1", 
                           "accepted"=>true
                          }
                }

  def setup
    License.const_set 'RESOURCES_DIR', File.join(File.dirname(__FILE__),"..","..","test","share")
    License.const_set 'VAR_DIR'      , File.join(File.dirname(__FILE__),"..","..","test","var")
    YaST::ConfigFile.stubs(:read_file).returns(YAML_CONTENT)
    YaST::ConfigFile.any_instance.stubs(:path).returns(__FILE__)
    License.any_instance.stubs(:save).returns(nil)

    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end

  def test_index
    ["xml", "json"].each do |format|
      get :index, {:format => format}
      assert_response :success
    end
  end

  def test_show
    ["xml", "json"].each do |format|
      get :show, {:format => format, :id => "1"}
      assert_response :success
    end
  end

  def test_update
    License.any_instance.expects(:save).returns(nil)
    get :update, UPDATE_DATA
    assert_response :success
    (more_update_data = UPDATE_DATA)["eulas"]["accepted"] = "true"
    get :update, more_update_data
    assert_response :success
  end

end
