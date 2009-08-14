require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "lsbservice"
require 'mocha'
require 'pp'

class LsbserviceTest < Test::Unit::TestCase

  def setup
    @services = Lsbservice.all
  end
  
end
