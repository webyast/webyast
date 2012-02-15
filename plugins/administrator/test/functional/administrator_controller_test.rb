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
require File.join(RailsParent.parent, "test","devise_helper")
require 'test/unit'


class AdministratorControllerTest < ActionController::TestCase
#  fixtures :accounts

  def setup
    devise_sign_in
    Administrator.stubs(:find).returns Administrator.new({:aliases => ""})
    AdministratorController.any_instance.stubs(:authorize!).with(:read, Administrator).returns(true)
  end
  
  test "check 'show' result" do

    ret = get :show, :format => "xml"
    # success (200 OK)
    assert_response :success

    # is returned a valid XML?
    ret_hash = Hash.from_xml(ret.body)
    assert ret_hash
    assert ret_hash.has_key?("administrator")
    assert ret_hash["administrator"].has_key?("aliases")
  end

end
