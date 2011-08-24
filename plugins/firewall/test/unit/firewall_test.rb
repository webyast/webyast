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

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class FirewallTest < ActiveSupport::TestCase

  FIREWALL_READ_DATA = { "use_firewall" => true,
                         "fw_services"  => [ {"name"   =>"WebYaST UI", 
                                              "id"     =>"service:webyast-ui", 
                                              "allowed"=>true}, 
                                             {"name"   =>"lighttpd", 
                                              "id"     =>"service:lighttpd-ssl", 
                                              "allowed"=>false}, 
                                             {"name"   =>"xdmcp", 
                                              "id"     =>"service:xdmcp", 
                                              "allowed"=>false} 
                                           ] 
                       }

  FIREWALL_WRITE_DATA = { "use_firewall" => true,
                          "fw_services"  => [ {"id"     =>"service:webyast-ui",
                                               "allowed"=>true},
                                              {"id"     =>"service:lighttpd-ssl",
                                               "allowed"=>false},
                                              {"id"     =>"service:xdmcp",
                                               "allowed"=>false}
                                            ]
                        }

  OK_RESULT = {"saved_ok" => true, "error" => ""}

  def setup
    YastService.stubs(:Call).with("YaPI::FIREWALL::Read").once.returns(FIREWALL_READ_DATA)
    Firewall.any_instance.stubs(:find).returns(FIREWALL_READ_DATA)
    @model = Firewall.find
  end

  def test_read
    assert_not_nil @model.use_firewall
    assert_instance_of(TrueClass, @model.use_firewall, "use_firewall() returns a TrueClass")
    assert_instance_of(Array, @model.fw_services, "fw_services() returns an Array")
    assert_instance_of(Hash, @model.fw_services.first, "single service is a Hash")
  end

  def test_write
    @model.fw_services[0]["allowed"] = true
    YastService.stubs(:Call).with("YaPI::FIREWALL::Write",Firewall.toVariantASV(FIREWALL_WRITE_DATA)).once.returns(OK_RESULT)
    assert_nothing_raised do
      @model.save
    end
  end
end
