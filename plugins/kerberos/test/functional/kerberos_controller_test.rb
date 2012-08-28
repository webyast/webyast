##--
## Copyright (c) 2009-2010 Novell, Inc.
##
## All Rights Reserved.
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of version 2 of the GNU General Public License
## as published by the Free Software Foundation.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, contact Novell, Inc.
##
## To contact Novell about this file by physical or electronic mail,
## you may find current contact information at www.novell.com
##++

require File.join(File.dirname(__FILE__),"..", "test_helper")
require File.join(RailsParent.parent, "test","devise_helper")

class KerberosControllerTest < ActionController::TestCase

  def setup
    devise_sign_in
    Kerberos.stubs(:find).returns(Kerberos.new({:default_domain => "site", :default_realm => "SITE", :enabled => false}))
    #Kerberos.any_instance.stubs(:save).returns(OK_RESULT)
    KerberosController.any_instance.stubs(:permission_check).with("org.opensuse.yast.modules.yapi.kerberos.read").returns(true)
    KerberosController.any_instance.stubs(:permission_check).with("org.opensuse.yast.modules.yapi.kerberos.write").returns(true)
    @model_class = Kerberos
  end

  test "should get index" do
    get :index
    assert_response :success
  end

   test "should get XML index" do
    ret = get :index, :format => "xml"
    ret_hash = Hash.from_xml(ret.body)
    assert ret_hash
    assert ret_hash.has_key?("kerberos")
    assert_equal false, ret_hash["kerberos"]["enabled"], false
    assert_equal "SITE", ret_hash["kerberos"]["default_realm"]
    assert_response :success
  end

end
