require 'test_helper'

class LanguageTest < ActiveSupport::TestCase

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
      "languages" => {"test" => "testing","a" => "b","c" => "d"}
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

#    debugger
    @language.read
    assert_equal("en_US", @language.language)
    assert_equal("ctype", @language.rootlocale)
    assert_equal("true", @language.utf8)
    languages = {
      "test" => "testing",
      "a" => "b",
      "c" => "d"
    }
    assert_equal(languages,@language.available)
  end

  def test_setter
    YastService.stubs(:Call).with("YaPI::LANGUAGE::Write",write_arguments).returns(true)
    @language.language = "de_DE"
    @language.rootlocale = "false"
    @language.utf8 = "false"
    @language.save
  end


end
