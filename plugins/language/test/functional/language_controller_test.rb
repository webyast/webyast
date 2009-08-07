require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class LanguageControllerTest < ActionController::TestCase
  fixtures :accounts
  
  def setup
    @model_class = Language
    @controller = LanguageController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @data = DATA

    Language.stubs(:available).returns(
      {  'rootlang' => 'ctype',                 
         'languages' => {
           'en_US' => [            
             'English (US)',
             'English (US)',
             '.UTF-8',      
             '',            
             'English (US)' ],               
           'fr_FR' => [
              'Français',
              'Francais',
              '.UTF-8',
              '@euro',
              'French' ],
            'de_DE' => [
              'Deutsch',
              'Deutsch',
              '.UTF-8',
              '@euro',
              'German' ]
         },
         'current' => 'en_US',
         'utf8' => 'true'
        } )

   @lang = Language.new
   @lang.language = "de_DE"
   @lang.rootlocale = "false"
   @lang.utf8 = "false"

   Language.stubs(:find).returns(@lang)
    
  end

  include PluginBasicTests

  DATA = {:language => {
      :current => "cs_CZ",
      :utf8 => "true",
      :rootlocale => "false"
    }}

  def test_update   
    Language.any_instance.stubs(:save)
    put :update, DATA
    check_update_result
  end

  def test_create
    Language.any_instance.stubs(:save)
    put :create, DATA
    check_update_result
  end

  def check_update_result
    assert_response :success
    lang = assigns(:language)
    assert lang
    assert_equal lang.language, DATA[:language][:current]
    assert_equal lang.utf8, DATA[:language][:utf8]
    assert_equal lang.rootlocale, DATA[:language][:rootlocale]
  end
end
