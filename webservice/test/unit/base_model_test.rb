require File.dirname(__FILE__) + '/../test_helper'
class BaseModelTest < ActiveSupport::TestCase
  class  Test < BaseModel::Base
    validates_presence_of :arg1
    validates_format_of :arg2, :with => /^\d$/
    before_save :call

    attr_accessor :arg1, :arg2, :callback_used
    attr_protected :callback_used
    def call
      @callback_used = true;
    end
  end

  class  Test2 < BaseModel::Base

    attr_accessor :arg1, :arg2
    attr_accessible :arg1
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
end
