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
    YastService.stubs(:Call).with('YaPI::ADMINISTRATOR::Read').returns({ "aliases" => [ "a@b" ] })
    @model = Administrator.find
  end

  def test_save_password
    YastService.stubs(:Call).with('YaPI::ADMINISTRATOR::Write', {"password" => ["s", "new password"]}).returns("")
    ret = Administrator.new({:password => "new password"}).save
    assert ret
  end

  def test_read_aliases
    YastService.stubs(:Call).with('YaPI::ADMINISTRATOR::Read').returns({ "aliases" => [ "a@b.c" ] })
    ret = Administrator.find
    assert ret
    puts ret.inspect
    assert ret.aliases.split(",").size == 1
  end

  def test_save_aliases
    @model.aliases	= "test@domain.com,a@b";
    YastService.stubs(:Call).with('YaPI::ADMINISTRATOR::Write', {"aliases" => [ "as", @model.aliases.split(",") ]}).returns("")
    ret = @model.save
    assert ret
    assert @model.aliases.split(",").size == 2
  end

end
