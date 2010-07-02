#--
# Webyast Webservice framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

require File.dirname(__FILE__) + '/../test_helper'
require "active_resource/http_mock"
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
    validates_uri :arg1
    def call
      @callback_used = true;
    end
  end

  class TestClient < ActiveResource::Base
    self.element_name = "test"
    self.site = "http://localhost"
  end


  def test_validations
    test = Test.new
    test.arg1 = "last"
    test.arg2 = "5"
    assert test.valid?
    test.arg1 = nil
    test.arg2 = "sda"
    assert test.invalid?
    test = Test3.new
    test.arg1 = "localhost:3000"
    assert test.valid?
    test.arg1 = "localhost:3000<script>frozen hell</script>"
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
  "test_data" => [ "a","b"], #serializers doesn't differ symbol from string and always sue string
  "test_data2" => [ 5,6], #number test
#  "test4" => [ true,false], # boolean doesn't work https://rails.lighthouseapp.com/projects/8994/tickets/5036-activeresource-load-problem-with-array-of-booleans#ticket-5036-1
  "test_data3" => { "a" => "b","c"=> "d" }, 
  "test_escapes" => "<arg>/&\\test",
  "test_hash" => [{"a"=>"a"},{"b"=>"b"}]
}

  def test_xml_serialization
    test= Test.new(MASS_DATA)
    test.carg = COMPLEX_DATA
    test.arg1 = TestSerializeItself.new
    xml = test.to_xml
    assert xml
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "test.xml",{},xml,200
    end
    TestClient.format = ActiveResource::Formats::XmlFormat
    test2 = TestClient.find :one, :from => "test.xml"
    assert_equal "lest", test2.arg1.test
    assert_equal "5", test2.arg2
    assert_equal COMPLEX_DATA["test_data"], test2.carg.test_data
    assert_equal COMPLEX_DATA["test_data2"], test2.carg.test_data2
    assert_equal COMPLEX_DATA["test_data3"]["a"], test2.carg.test_data3.a
    assert_equal COMPLEX_DATA["test_escapes"], test2.carg.test_escapes
    assert_equal COMPLEX_DATA["test_hash"][0]["a"], test2.carg.test_hash[0].a
  end

  def test_json_serialization
    test= Test.new(MASS_DATA)
    test.carg = COMPLEX_DATA
    json = test.to_json
    assert json
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "test.json",{},json,200
    end
    TestClient.format = :json
    test2 = TestClient.find :one, :from => "test.json"
    assert_equal "last", test2.arg1
    assert_equal "5", test2.arg2
    assert_equal COMPLEX_DATA["test_data"], test2.carg.test_data
    assert_equal COMPLEX_DATA["test_data2"], test2.carg.test_data2
    assert_equal COMPLEX_DATA["test_data3"]["a"], test2.carg.test_data3.a
    assert_equal COMPLEX_DATA["test_escapes"], test2.carg.test_escapes
    assert_equal COMPLEX_DATA["test_hash"][0]["a"], test2.carg.test_hash[0].a
  end

  def test_attr_serializable
    test = Test3.new
    test.arg1 = "dev"
    test.arg2 = "null"
    xml = test.to_xml
    assert xml
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "test.xml",{},xml,200
    end
    TestClient.format = ActiveResource::Formats::XmlFormat
    test2 = TestClient.find :one, :from => "test.xml"
    assert_equal "dev",test2.arg1
    assert !test2.respond_to?(:arg2)
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
