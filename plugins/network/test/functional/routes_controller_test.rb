require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require 'route'
require "scr"
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class RoutesControllerTest < Test::Unit::TestCase

 # this is test only for mocked data - not very useful
 # we need to extend it to test both model and controller
 # to extract routes data from all YaPI map
 #
 def test_show
    # if this code raises, test-unit 2.0.3 and mocha 0.9.5 fail
    # with PASSTHROUGH_EXCEPTIONS. version mismatch?!
    Route.expects(:find).returns({:routes=>{:default=>{'via'=>'10.20.30.40'}}})
    Route.find
 end

end

