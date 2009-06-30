require 'test_helper'



class LanguageTest < ActiveSupport::TestCase

  Test_Lang = {
      "test" => ["testing","la testing",".utf","la t"],
      "a" => ["b","b","b","b"],
      "c" => ["d","d","d","d"]
    }

  def read_arguments
    return {
      "current"=> "true",
      "utf8"=> "true",
      "rootlang"=> "true",
      "languages" => "true"
    }
  end

  def read_response
    return {
      "current" => "en_US",
      "utf8" => "true",
      "rootlang" => "ctype",
      "languages" => Test_Lang
    }
  end

  def write_arguments
    return {
      "current" => "de_DE",
      "utf8" => "false",
      "rootlang" => "false",
    }
  end

  def setup    
    @language = Language.new        
  end

  
  def test_getter
    YastService.stubs(:Call).with("YaPI::LANGUAGE::Read",read_arguments).returns(read_response)

    @language.read
    assert_equal("en_US", @language.language)
    assert_equal("ctype", @language.rootlocale)
    assert_equal("true", @language.utf8)
    assert_equal(Test_Lang,@language.available)
  end

  def test_setter
    YastService.stubs(:Call).with("YaPI::LANGUAGE::Write",write_arguments).returns(true)

    @language.language = "de_DE"
    @language.rootlocale = "false"
    @language.utf8 = "false"
    @language.save
  end

  def test_xml
    #inject Language to set available for direct testing
    def @language.available=(val)
      @@available=val
    end

    @language.language = "de_DE"
    @language.rootlocale = "false"
    @language.utf8 = "false"
    @language.available = Test_Lang

    response = Hash.from_xml(@language.to_xml)
    response = response["language"]

    assert_equal("de_DE", response["current"])
    assert_equal("false", response["utf8"])
    assert_equal("false", response["rootlocale"])
    lang_reponse = [
      {"id" => "test", "name" => "testing" },
      {"id" => "a", "name" => "b" },
      {"id" => "c", "name" => "d" }
    ]
    assert_equal(lang_reponse.sort { |a,b| a["id"] <=> b["id"] },
      response["available"].sort { |a,b| a["id"] <=> b["id"] })
  end

  def test_json
    def @language.available=(val)
      @@available=val
    end
    
    @language.language = "de_DE"
    @language.rootlocale = "false"
    @language.utf8 = "false"
    @language.available = Test_Lang

    assert_not_nil(@language.to_json)
  end

end
