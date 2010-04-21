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

require 'administrator'

class AdministratorTest < ActiveSupport::TestCase

  def setup    
    @model = Administrator.instance
    YastService.stubs(:Call).with('YaPI::ADMINISTRATOR::Read').returns({ "aliases" => [ "a@b" ] })
    @model.read_aliases
  end

  def test_save_password
    YastService.stubs(:Call).with('YaPI::ADMINISTRATOR::Write', {"password" => ["s", "new password"]}).returns("")
    ret = @model.save_password("new password")
    assert ret
  end

  def test_read_aliases
    YastService.stubs(:Call).with('YaPI::ADMINISTRATOR::Read').returns({ "aliases" => [ "a@b.c" ] })
    ret = @model.read_aliases
    assert ret
    assert @model.aliases.split(",").size == 1
  end

  def test_save_aliases
    new_aliases	= [ "test@domain.com", "a@b" ];
    YastService.stubs(:Call).with('YaPI::ADMINISTRATOR::Write', {"aliases" => [ "as", new_aliases ]}).returns("")
    ret = @model.save_aliases(new_aliases.join(","))
    assert ret
    assert @model.aliases.split(",").size == 2
  end

  def test_save_empty_aliases
    new_aliases	= "NONE"
    YastService.stubs(:Call).with('YaPI::ADMINISTRATOR::Write', {"aliases" => [ "as", [] ]}).returns("")
    ret = @model.save_aliases(new_aliases)
    assert ret
    assert @model.aliases.empty?
  end

  def test_save_failure
    new_aliases	= [ "test@domain.com" ];
    YastService.stubs(:Call).with('YaPI::ADMINISTRATOR::Write', {"aliases" => [ "as", new_aliases ]}).returns("YaPI error")
    assert_raise AdministratorError do
      ret = @model.save_aliases(new_aliases.join(","))
    end
  end

  def test_save_no_change
    new_aliases	= [ "a@b" ];
    ret = @model.save_aliases(new_aliases.join(","))
    assert ret
    assert @model.aliases.split(",").size == 1
  end

end
