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

require 'mail'

class MailTest < ActiveSupport::TestCase

  def setup    
    @model = Mail.instance
    YastService.stubs(:Call).with('YaPI::MailSettings::Read').returns({ })
    @model.read
  end

  def test_read_notls
    YastService.stubs(:Call).with('YaPI::MailSettings::Read').returns({
	"smtp_server" => "smtp.domain.com"
    })
    ret = @model.read
    assert @model.transport_layer_security == "no"
  end

  def test_read
    YastService.stubs(:Call).with('YaPI::MailSettings::Read').returns({
	"smtp_server"	=> "smtp.domain.com",
	"TLS"		=> "must"
    })
    ret = @model.read
    assert @model.smtp_server == "smtp.domain.com"
    assert @model.transport_layer_security == "must"
  end


  def test_save
    YastService.stubs(:Call).with('YaPI::MailSettings::Write', {
	"smtp_server"	=> [ "s", "smtp.newdomain.com"],
	"TLS"		=> [ "s", "no"],
	"user"		=> [ "s", ""],
	"password"	=> [ "s", ""]
    }).returns("")
    ret = @model.save({
	"smtp_server"	=> "smtp.newdomain.com",
	"user"		=> "",
	"password"	=> "",
	"transport_layer_security"	=> "no"
    })
    assert ret
  end


#  def test_save_failure
#  end

end
