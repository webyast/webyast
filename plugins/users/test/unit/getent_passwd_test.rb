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
require 'test/unit'

class GetentPasswdTest < Test::Unit::TestCase

GETENT_OUTPUT = <<EOF
  rtkit:x:116:124:RealtimeKit:/proc:/sbin/nologin
  local:x:1000:100:Local user:/home/local:/bin/sh
  ldap:*:10063:100:LDAP User:/home/ldap:/bin/bash
  nobody:*:65534:100:nobody:/home/nobody:/bin/false
EOF

WBINFO_OUTPUT = <<EOF
  WIN\Administrator
EOF

  def setup
    GetentPasswd.stubs(:system_minimum).returns(1000)
    GetentPasswd.stubs(:pure_getent).returns(GETENT_OUTPUT)
    GetentPasswd.stubs(:pure_wbinfo).returns(WBINFO_OUTPUT)
  end

  def test_find
    result = GetentPasswd.find
    assert result
    assert_equal 3,result.size
  end

  
end
