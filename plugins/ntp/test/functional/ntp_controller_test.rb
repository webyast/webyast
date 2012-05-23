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

#don't have plugin basic tests because doesn't have read permission

class NtpControllerTest < ActionController::TestCase

  def setup    
    devise_sign_in
    YastService.stubs(:Call).with("YaPI::NTP::Available").returns(true)
    Ntp.stubs(:get_servers_string).returns("")
  end

  def test_index
    @request.accept = Mime::XML
    ret = get :show, :format => "xml" 
    assert_response :success
    response = Hash.from_xml(ret.body)
    assert response["ntp"]["actions"]["synchronize"] == false
  end

  def test_update
    @request.accept = Mime::XML
    YastService.stubs(:Call).with("YaPI::NTP::Synchronize",true,"").once.returns("OK")
    post :update, {"ntp"=>{"actions" => {"synchronize"=>true,"synchronize_utc"=>true}}}, :format => "xml" 
    assert_response :success
  end

  def test_update_failed
    YastService.stubs(:Call).with("YaPI::NTP::Synchronize",false,"").once.returns("Failed")
    post :update, {"ntp"=>{"actions" => {"synchronize"=>true,"synchronize_utc" => false}}}
    assert_response 503
  end

end
