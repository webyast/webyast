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

require 'ldap'

class LdapTest < ActiveSupport::TestCase

  def setup    
    YastService.stubs(:Call).with('YaPI::LDAP::Read').returns({
	"ldap_server"	=> "ldap.suse.de",
	"ldap_domain"	=> "dc=suse,dc=de",
	"start_ldap"	=> "1",
	"ldap_tls"	=> "0"
    })
  end

  def test_read
    ret		= Ldap.find
    assert ret
    assert ret.enabled
  end

  def test_write
    ldap	= Ldap.find
    ldap.server		= "ldap.suse.cz"
    ldap.base_dn	= "dc=suse,dc=cz"
    YastService.stubs(:Call).with('YaPI::LDAP::Write', {
	"ldap_server"	=> [ "s", "ldap.suse.cz"],
	"ldap_domain"	=> [ "s", "dc=suse,dc=cz"],
	"start_ldap"	=> [ "b", true],
	"ldap_tls"	=> [ "b", false]
    }).returns(0)
    ldap.save
  end

end
