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

#
# test ApplicationController::rescue_from
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class RaisingControllerTest < ActionController::TestCase

  class RaisingController < ApplicationController
    def noPermission
      raise NoPermissionError.new("test.permission", "test_user")
    end
    
    def raiseNotFound
      raise YaST::ConfigFile::NotFoundError.new("/dev/null") #frozen hell
    end

    def raiseInvalidParameters
      raise InvalidParameters.new( :heaven => "MISSING" )
    end

    def raiseDBusError
      m = DBus::Message.new
      raise DBus::Error.new(DBus::Message.error(m, "DBusError", "testing DBus::Error"))
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

  def test_dbus_error
    get :raiseDBusError
    assert_response 503
  end

  # NoPermissionException should return 403 - Forbidden
  def test_no_permission
    get :noPermission
    assert_response 403
  end

end
