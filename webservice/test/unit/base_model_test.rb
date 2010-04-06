require File.dirname(__FILE__) + '/../test_helper'
class BaseModelTest < ActiveSupport::TestCase
  class  Test < BaseModel::Base
    validates_presence_of :arg1
    validates_format_of :arg2, :with => /^\d$/
    before_save :call

    attr_accessor :arg1, :arg2, :callback_used, :carg
    attr_protected :callback_used
    def call
      @callback_used = true;
    end
  end

  class  Test2 < BaseModel::Base

    attr_accessor :arg1, :arg2
    attr_accessible :arg1
    attr_serialized :arg1
    def call
      @callback_used = true;
    end
  end

  class  Test3 < BaseModel::Base

    attr_accessor :arg1, :arg2
    attr_serialized :arg1
    def call
      @callback_used = true;
    end
  end

  def test_validations
    test = Test.new
    test.arg1 = "last"
    test.arg2 = "5"
    assert test.valid?
    test.arg1 = nil
    test.arg2 = "sda"
    assert test.invalid?
  end

  def test_save!
    test = Test.new
    test.arg1 = nil
    test.arg2 = "sda"
    assert_raise InvalidParameters do
      test.save!
    end
  end

  def test_callbacks
    test = Test.new
    test.callback_used = false
    assert test.save(false)
    assert test.callback_used
  end

MASS_DATA = { :arg1 => "last", :arg2 => "5", :callback_used => false }
  def test_mass_assignment
    test = Test.new
    test.callback_used = true
    test.load MASS_DATA
    assert_equal "last", test.arg1
    assert_equal "5", test.arg2
#test blacklisting
    assert test.callback_used
#test whitelisting
    test2 = Test2.new(MASS_DATA)
    assert_equal "last", test2.arg1
    assert test2.arg2.nil?
  end

class TestSerializeItself
  def to_xml(options={})
    root = options[:root] || @model.class.model_name.singular
    builder = options[:builder] || Builder::XmlMarkup.new(options)
    builder.instruct! unless options[:skip_instruct]
    builder.tag!(root) do
      builder.test "lest"
      builder.test2 "lest2"
    end
  end
end

COMPLEX_DATA = {
  "test" => [ "a","b"], #serializers doesn't differ symbol from string and always sue string
  "test2" => [ 5,6], #number test
  "test4" => [ true,false], #number boolean
  "test3" => { "a" => "b","c"=> "d" }, 
  "test_escapes" => "<arg>/&\\test",
  "test_hash" => [{"a"=>"a"},{"b"=>"b"}]
}

  def test_xml_serialization
    test= Test.new(MASS_DATA)
    test.carg = COMPLEX_DATA
    test.arg1 = TestSerializeItself.new
    xml = test.to_xml
    assert xml
    test2 = Test.new
    test2.from_xml xml
    assert_equal({"test" => "lest","test2" => "lest2"}, test2.arg1)
    assert_equal "5", test2.arg2
    assert_equal COMPLEX_DATA, test2.carg
  end

  def test_json_serialization
    test= Test.new(MASS_DATA)
    test.carg = COMPLEX_DATA
    json = test.to_json
    assert json
    test2 = Test.new
    test2.from_json json
    assert_equal "last", test2.arg1
    assert_equal "5", test2.arg2
    assert_equal COMPLEX_DATA, test2.carg
  end

  def test_attr_serializable
    test = Test3.new
    test.arg1 = "dev"
    test.arg2 = "null"
    xml = test.to_xml
    assert xml
    test2 = Test3.new
    test2.from_xml xml
    assert_equal "dev",test2.arg1
    assert_nil test2.arg2
    test = Test3.new
    test.arg1 = "dev"
    test.arg2 = "null"
    json = test.to_json
    assert json
    test2 = Test3.new
    test2.from_json json
    assert_equal "dev",test2.arg1
    assert_nil test2.arg2
  end
end
