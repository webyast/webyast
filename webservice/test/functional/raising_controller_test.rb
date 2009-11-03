require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class RaisingControllerTest < ActionController::TestCase

  class RaisingController < ApplicationController
    def raiseNotFound
      raise YaST::ConfigFile::NotFoundError.new("/dev/null") #frozen hell
    end

    def raiseInvalidParameters
      raise InvalidParameters.new( :heaven => "MISSING" )
    end

    def raiseBackendException
      raise BackendException
    end

    def raiseException
      raise "WTF?"
    end
  end

  def setup
    @controller = RaisingController.new
    @routes = ActionController::Routing::Routes.routes.dup
    # add a catch-all route for the tests only.
    ActionController::Routing::Routes.draw { 
      |map| map.connect ':controller/:action'
    }
  end

  def teardown
    #restore original routes to not affect other tests
    ActionController::Routing::Routes.routes = @routes
  end

  def test_catch_not_found
    get :raiseNotFound
    assert_response 503
  end

  def test_catch_invalid
    get :raiseInvalidParameters
    assert_response 422
  end

  def test_catch_backend_exception
    get :raiseBackendException
    assert_response 503
  end

  def test_catch_exception
    get :raiseException
    assert_response 500
  end

end
