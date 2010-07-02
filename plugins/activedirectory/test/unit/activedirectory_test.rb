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

require 'activedirectory'

class ActivedirectoryTest < ActiveSupport::TestCase

  def setup    
    YastService.stubs(:Call).with('YaPI::ActiveDirectory::Read',{}).returns({
	"domain"	=> "AD.DOMAIN.COM",
	"mkhomedir"	=> "0",
	"winbind"	=> "1"
    })
  end

  def test_read
    ret		= Activedirectory.find
    assert ret
    assert ret.enabled
    assert !ret.create_dirs
  end

  # when only disabling, no need to check the member status
  def test_write_disable
    ad		= Activedirectory.find
    ad.enabled	= false
    YastService.stubs(:Call).with('YaPI::ActiveDirectory::Write', {
	"domain"	=> [ "s", "AD.DOMAIN.COM"],
	"winbind"	=> [ "b", false],
	"mkhomedir"	=> [ "b", false]
    }).returns({})
    ad.save
  end

  # before writing, Read call is done to check the member status
  def test_write_not_joined
    ad		= Activedirectory.find
    ad.domain	= "DIFFERENT.DOMAIN.COM"
    YastService.stubs(:Call).with('YaPI::ActiveDirectory::Read',{
	"check_membership"	=> [ "s", "DIFFERENT.DOMAIN.COM"]
    }).returns({
	"result"		=> false
    })
    exception = nil
    begin
      ad.save
    rescue ActivedirectoryError => e
      exception = e
    end
    assert_not_nil exception, "should raise exception"
    assert_equal "not_member",exception.id
  end

  def test_write_already_joined
    ad		= Activedirectory.find
    ad.domain	= "DIFFERENT.DOMAIN.COM"
    YastService.stubs(:Call).with('YaPI::ActiveDirectory::Read',{
	"check_membership"	=> [ "s", "DIFFERENT.DOMAIN.COM"]
    }).returns({
	"result"		=> true
    })
    # after check that we are joined, write is called
    YastService.stubs(:Call).with('YaPI::ActiveDirectory::Write', {
	"domain"	=> [ "s", "DIFFERENT.DOMAIN.COM"],
	"winbind"	=> [ "b", true],
	"mkhomedir"	=> [ "b", false]
    }).returns({})
    ad.save
  end

  def test_write_error_on_write
    ad		= Activedirectory.find
    ad.domain	= "DIFFERENT.DOMAIN.COM"
    YastService.stubs(:Call).with('YaPI::ActiveDirectory::Read',{
	"check_membership"	=> [ "s", "DIFFERENT.DOMAIN.COM"]
    }).returns({
	"result"		=> true
    })
    YastService.stubs(:Call).with('YaPI::ActiveDirectory::Write', {
	"domain"	=> [ "s", "DIFFERENT.DOMAIN.COM"],
	"winbind"	=> [ "b", true],
	"mkhomedir"	=> [ "b", false]
    }).returns({
	"write_error"	=> true
    })
    exception = nil
    begin
      ad.save
    rescue ActivedirectoryError => e
      exception = e
    end
    assert_not_nil exception, "should raise exception"
    assert_equal "write_error",exception.id
  end

  # when credentials are given, there's only one write call
  def test_join_and_write
    ad		= Activedirectory.find
    ad.domain	= "DIFFERENT.DOMAIN.COM"
    ad.administrator	= "Administrator"
    ad.password		= "heslo"

    YastService.stubs(:Call).with('YaPI::ActiveDirectory::Write', {
	"domain"	=> [ "s", "DIFFERENT.DOMAIN.COM"],
	"winbind"	=> [ "b", true],
	"mkhomedir"	=> [ "b", false],
	"administrator"	=> [ "s", "Administrator" ],
	"password"	=> [ "s",  "heslo" ]
    }).returns({})
    ad.save
  end

  def test_join_failure
    ad		= Activedirectory.find
    ad.domain	= "DIFFERENT.DOMAIN.COM"
    ad.administrator	= "Administrator"
    ad.password		= "heslo"

    YastService.stubs(:Call).with('YaPI::ActiveDirectory::Write', {
	"domain"	=> [ "s", "DIFFERENT.DOMAIN.COM"],
	"winbind"	=> [ "b", true],
	"mkhomedir"	=> [ "b", false],
	"administrator"	=> [ "s", "Administrator" ],
	"password"	=> [ "s",  "heslo" ]
    }).returns({
	"join_error"	=> "something got wrong"
    })
    exception = nil
    begin
      ad.save
    rescue ActivedirectoryError => e
      exception = e
    end
    assert_not_nil exception, "should raise exception"
    assert_equal "join_error",exception.id
  end

end
