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

require 'kerberos'

class KerberosTest < ActiveSupport::TestCase

  def setup    
    YastService.stubs(:Call).with('YaPI::KERBEROS::Read', {}).returns({
	"kdc"			=> "kdc.suse.cz",
	"default_domain"	=> "suse.cz",
	"default_realm"		=> "SUSE.CZ",
	"use_kerberos"		=> "1",
    })
  end

  def test_read
    ret		= Kerberos.find
    assert ret
    assert ret.enabled
  end

  def test_write
    kerberos			= Kerberos.find
    kerberos.kdc		= "kdc.novell.com"
    kerberos.default_domain	= "novell.com"
    YastService.stubs(:Call).with('YaPI::KERBEROS::Write', {
	"kdc"		=> [ "s", "kdc.novell.com"],
	"default_domain"=> [ "s", "novell.com"],
	"default_realm"	=> [ "s", "SUSE.CZ"],
	"use_kerberos"	=> [ "b", true]
    }).returns(0)
    kerberos.save
  end

end
