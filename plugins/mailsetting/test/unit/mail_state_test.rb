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

class MailStateTest < ActiveSupport::TestCase

  def setup    
    Mailsetting.const_set("TEST_MAIL_FILE", File.join(File.dirname(__FILE__), '..', 'fixtures', 'empty_mail_settings')) 
  end


  def test_read
    ret = MailState.read
    assert ret[:confirmation_label]=="Test mail received"
  end

end
