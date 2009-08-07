require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class LanguageTest < ActiveSupport::TestCase

  LANGUAGES = {
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
   }

  ARGS_FULL = {
    "current"=> "true",
    "utf8"=> "true",
    "rootlang"=> "true",
    "languages" => "true"
  }

  ARGS_PARTIAL = {
    "current"=> "true",
    "utf8"=> "true",
    "rootlang"=> "true"
  }
  
  RESPONSE_FULL = {
    "current" => "en_US",
    "utf8" => "true",
    "rootlang" => "ctype",
    "languages" => LANGUAGES }

  RESPONSE_PARTIAL = {
    "current" => "en_US",
    "utf8" => "true",
    "rootlang" => "ctype" }
  
  ARGS_WRITE = {
    "current" => "de_DE",
    "utf8" => "false",
    "rootlang" => "false" }

  def setup    
    YastService.stubs(:Call).with("YaPI::LANGUAGE::Read",ARGS_FULL).returns(RESPONSE_FULL)
    YastService.stubs(:Call).with("YaPI::LANGUAGE::Read",ARGS_PARTIAL).returns(RESPONSE_PARTIAL)
    YastService.stubs(:Call).with("YaPI::LANGUAGE::Write",ARGS_WRITE).returns(true)
  end

  def test_getter
    lang = Language.find
#    pp Language.available

    assert_equal("en_US", lang.language)
    assert_equal("ctype", lang.rootlocale)
    assert_equal("true", lang.utf8)
    assert_equal(LANGUAGES,Language.available)
  end

  def test_setter
    lang = Language.find
    lang.language = "de_DE"
    lang.rootlocale = "false"
    lang.utf8 = "false"
    lang.save
  end

  def test_xml
    lang = Language.find
    lang.language = "de_DE"
    lang.rootlocale = "false"
    lang.utf8 = "false"

    response = Hash.from_xml(lang.to_xml)
    response = response["language"]

    assert_equal("de_DE", response["current"])
    assert_equal("false", response["utf8"])
    assert_equal("false", response["rootlocale"])
    lang_reponse = [ {"name"=>"Deutsch", "id"=>"de_DE"},
                     {"name"=>"English (US)", "id"=>"en_US"},
                     {"name"=>"Français", "id"=>"fr_FR"} ]
    
    assert_equal(lang_reponse.sort { |a,b| a["id"] <=> b["id"] },
      response["available"].sort { |a,b| a["id"] <=> b["id"] })
  end

  def test_json
    lang = Language.find
    lang.language = "de_DE"
    lang.rootlocale = "false"
    lang.utf8 = "false"
 
    assert_not_nil(lang.to_json)
  end

end
