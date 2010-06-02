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

require 'gettext'

class MailState
  include GetText
  def self.read()
    if File.exist? Mail::TEST_MAIL_FILE
      f = File.new(Mail::TEST_MAIL_FILE, 'r')
      mail = f.gets.chomp
      mail = "" if mail.nil?
      f.close

      require "socket"

      details	= ""

      begin
	host 	= Socket.gethostbyname(Socket.gethostname).first
      rescue SocketError => e
	details	= _("It was not possible to retrieve the full hostname of the machine. If the mail could not be delivered, consult the network and/or mail configuration with your network administrator.")
      end

      return { :level => "warning",
               :message_id => "MAIL_SENT",
               :short_description => _("Mail configuration test not confirmed"),
               :long_description => _("While configuring mail, a test mail was sent to %s . Was the mail delivered to this address?<br>If so, confirm it by pressing the button. Otherwise check your mail configuration again.") % mail,
	       :details	=> details,
               :confirmation_host => "service",
               :confirmation_link => "/mail/state",
               :confirmation_label => _("Test mail received"),
               :confirmation_kind => "button" } 
      # TODO what about passing :log_file => '/var/log/mail', so status page could show its content?
    else
      return {}
    end   
  end
end
