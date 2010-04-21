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
module Registration
  class RegistrationControllerTest < ActionController::TestCase
    fixtures :accounts
  
    def setup
      @request = ActionController::TestRequest.new
      # http://railsforum.com/viewtopic.php?id=1719
      @request.session[:account_id] = 1 # defined in fixtures

      @data = { 'options'=>{'debug'=>2,
                         'forcereg'=>false,
                         'nooptional'=>true,
                         'nohwdata'=>true,
                         'optional'=>false,
                         'hwdata'=>false},
                'arguments'=>[{'name'=>'key','value'=>'val'}] }


      Register.stubs(:register).with(@data).returns(
      { 'status'=>'finished',
        'exitcode'=>0,
        'guid'=>1234,
        'changedrepos'=>[{'name'=>'repoName', 
                          'alias'=>'myRepoName', 
                          'urls'=>['http://some.host/repo/xy'],
                          'priority'=>80,
                          'autorefresh'=>true,
                          'enabled'=>true,
                          'status'=>'added'}],
        'changedservices'=>[{'name'=>'some-serv1',
                             'url'=>'http://some.host/services/serv1',
                             'status'=>'added'}]
      })
    end

    def test_access_denied
      #mock model to test only controller
      @controller.stubs(:permission_check).raises(NoPermissionException.new("action", "test"));
      get :show
      assert_response 503
    end

# FIXME: temporarily disabled - mocking is missing, it calls the DBus service and fails!
#    def test_access_show_xml
#      mime = Mime::XML
#      get :show, :format => 'xml'
#      assert_equal mime.to_s, @response.content_type
#    end

# FIXME: temporarily disabled - mocking is missing, it calls the DBus service and fails!
#    def test_access_show_json
#      mime = Mime::JSON
#      get :show, :format => 'json'
#      assert_equal mime.to_s, @response.content_type
#    end

    def test_register_noparams
#      put :create    
#      assert_response 422
    end

    def test_register_noperm
      @controller.stubs(:permission_check).raises(NoPermissionException.new("action", "test"));
      put :create, @data
      assert_response  503
  end

  def test_register
#     put :create, @data
#     assert_response :success
  end

end
end
