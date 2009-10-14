require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class RegistrationControllerTest < ActionController::TestCase
  fixtures :accounts
  
  def setup
    @controller = RegistrationController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures

    Registration.stubs(:register).returns(
      { 'status'=>'finished',
        'exitcode'=>0,
        'guid'=>1234,
        'missingarguments'=>[{'name'=>'missingkey', 'type'=>'string'}],
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

   Registration.stubs(:find).returns({})

   @data = { 'options'=>{'debug'=>2,
                         'forcereg'=>false,
                         'nooptional'=>true,
                         'nohwdata'=>true,
                         'optional'=>false,
                         'hwdata'=>false},
             'arguments'=>[{'name'=>'key','value'=>'val'}] }
  end

  def test_access_denied
    #mock model to test only controller
#    @controller.stubs(:permission_check).raises(NoPermissionException.new("action", "test"));
#    get :show
#    assert_response 503
  end

  def test_access_show_xml
#    mime = Mime::XML
#    get :show, :format => 'xml'
#    assert_equal mime.to_s, @response.content_type
  end

  def test_access_show_json
#    mime = Mime::JSON
#    get :show, :format => 'json'
#    assert_equal mime.to_s, @response.content_type
  end

  def test_register_noparams
#    put :create    
#    assert_response 422
  end

  def test_register_noperm
#    @controller.stubs(:permission_check).raises(NoPermissionException.new("action", "test"));
#    put :create, @data

#    assert_response  503
  end

  def test_register
#    put :create, @data
#    assert_response :success
  end

end
