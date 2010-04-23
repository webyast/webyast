#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

require File.join(File.dirname(__FILE__),"..", "test_helper")
require File.join(RailsParent.parent, "test","plugin_basic_tests")

class FirewallControllerTest < ActionController::TestCase
  fixtures :accounts

  INITIAL_DATA ={ "use_firewall" => true,
                  "fw_services"  => [ {"name"   =>"WebYaST UI",
                                       "id"     =>"service:webyast-ui",
                                       "allowed"=>false},
                                      {"name"   =>"lighttpd",
                                       "id"     =>"service:lighttpd-ssl",
                                       "allowed"=>false}
                                    ]
                }
  UPDATE_DATA = {"firewall" => { "use_firewall" => true,
                                 "fw_services"  => [ {"name"   =>"WebYaST UI",
                                                      "id"     =>"service:webyast-ui",
                                                      "allowed"=>true},
                                                     {"name"   =>"lighttpd",
                                                      "id"     =>"service:lighttpd-ssl",
                                                      "allowed"=>false}
                                                   ]
                            }
                }
  DATA = { "use_firewall" => true,
           "fw_services"  => [ {"id"     =>"service:webyast-ui",
                                "allowed"=>true},
                               {"id"     =>"service:lighttpd-ssl",
                                "allowed"=>false}
                             ]
         }

  OK_RESULT = {"saved_ok" => true, "error" => ""}

  def setup
    @model_class = Firewall
    fw_mock = Firewall.new(INITIAL_DATA)
    Firewall.stubs(:find).returns(fw_mock)

    @controller = FirewallController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @data = UPDATE_DATA
  end

  include PluginBasicTests

  def test_update
    mock_save
    put :update, UPDATE_DATA
    assert_response :success
  end

  def test_create
    mock_save
    put :create, UPDATE_DATA
    assert_response :success
  end

  def mock_save
    YastService.stubs(:Call).with( "YaPI::FIREWALL::Write", Firewall.toVariantASV(DATA)).once.returns(OK_RESULT)
    Firewall.stubs(:permission_check)
  end
end
