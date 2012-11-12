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
class RegistrationControllerTest < ActionController::TestCase

  # TODO: add mirroring credentials test (use fixtures/mirror-credentials.xml for testing)

  def setup
    devise_sign_in
    @data = { :registration => { 'options'=>{'debug'=>2,
                       'forcereg'=>false,
                       'nooptional'=>true,
                       'nohwdata'=>true,
                       'optional'=>false,
                       'hwdata'=>false},
        'arguments'=>[{'name'=>'key','value'=>'val'}] }}
    Register.any_instance.stubs(:register).returns(0)
    Register.any_instance.stubs(:status).returns('finished')
    Register.any_instance.stubs(:guid).returns(1234)
    Register.any_instance.stubs(:changedrepos).returns([{'name'=>'repoName', 
                        'alias'=>'myRepoName', 
                        'urls'=>['http://some.host/repo/xy'],
                        'priority'=>80,
                        'autorefresh'=>true,
                        'enabled'=>true,
                        'status'=>'added'}])
    Register.any_instance.stubs(:changedservices).returns([{'name'=>'some-serv1',
                           'url'=>'http://some.host/services/serv1',
                           'status'=>'added'}])
    YastService.stubs(:Call).with("YSR::getregistrationconfig").returns(
    {"regserverurl"=>"https://secure-www.novell.com/center/regsvc/", "guid"=>"", "regserverca"=>""})
  end

  def test_access_denied
    #mock model to test only controller
    @controller.stubs(:authorize!).raises(CanCan::AccessDenied.new());
    mime = Mime::XML
    get :show, :format => 'xml'
    assert_response 403
  end

  def test_access_show_xml
    mime = Mime::XML
    get :show, :format => 'xml'
    assert_equal mime.to_s, @response.content_type
  end

  def test_access_show_json
     mime = Mime::JSON
     get :show, :format => 'json'
     assert_equal mime.to_s, @response.content_type
  end

  def test_register_noparams
    mime = Mime::XML
    put :create    
    assert_response 422
  end

  def test_register_noperm
    @controller.stubs(:authorize!).raises(CanCan::AccessDenied.new());
    mime = Mime::XML
    @data[:format] = 'xml'
    put :create, @data
    assert_response 403
  end

  def test_register
    mime = Mime::XML
    @data[:format] = 'xml'
    put :create, @data
    assert_response :success
  end

  def test_register_ui
    post :update, {"registration_arg_Registration Name"=>"registrationName", "registration_arg_System Name"=>"systemName", "registration_arg_Email"=>"email" }
    assert_response :redirect
    assert_redirected_to '/', :action => "index"
  end

  def test_register_in_basesystem
    session[:wizard_current] = "registration"
    session[:wizard_steps] = "language,registration,test"

    bs = Basesystem.new.load_from_session(session)
    Basesystem.stubs(:find).returns(bs)
    Basesystem.any_instance.stubs(:completed?).returns(false)

    post :update, {"registration_arg_Registration Name"=>"registrationName", "registration_arg_System Name"=>"systemName", "registration_arg_Email"=>"email" }
    assert_response :redirect
    assert_redirected_to '/controlpanel/nextstep?done=registration'
  end

  def test_already_registered

    get :index
    assert_response 200
    assert_valid_markup
  end
end
