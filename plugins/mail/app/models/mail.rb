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

require 'singleton'
require 'yast_service'
require 'webyast/paths'
require 'base'
require 'builder'

# = Mail model
# Proviceds access local mail settings (SMTP server to use)
# Uses YaPI::MailSettings for read and write operations,
# YaPI::SERVICES, for reloading postfix service.
class Mail < BaseModel::Base

  attr_accessor :smtp_server
  attr_accessor :user
  attr_accessor :password
  attr_accessor :confirm_password
  attr_accessor :test_mail_address
  attr_accessor :transport_layer_security

  TEST_MAIL_FILE = File.join(WebYaST::Paths::VAR,"mail","test_sent")

  # read the settings from system
  def self.find
    YastCache.fetch(self) {
      yapi_ret = YastService.Call("YaPI::MailSettings::Read")
      raise MailError.new("Cannot read from YaPI backend") if yapi_ret.nil?
      yapi_ret["transport_layer_security"] = yapi_ret.delete("TLS") || "no"
      Mail.new yapi_ret
    }
  end


  # Save new mail settings
  def update

    parameters	= {
	"smtp_server"	=> [ "s", smtp_server ||""],
	"user"		=> [ "s", user ||""],
	"password"	=> [ "s", password ||""],
	"TLS"		=> [ "s", transport_layer_security ||""]
    }

    yapi_ret = YastService.Call("YaPI::MailSettings::Write", parameters)
    Rails.logger.debug "YaPI returns: '#{yapi_ret}'"
    YastCache.reset(self)
    raise MailError.new(yapi_ret) unless yapi_ret.empty?
    true
  end

  def self.send_test_mail(to)
    return if to.nil? || to.empty?

    Rails.logger.debug "sending test mail to #{to}..."

    message	= "This is the test mail sent to you by webYaST. Go to the status page and confirm you've got it."

    # remove potential problematic characters from email address
    to.tr!("~'\"<>","")
    `/bin/echo "#{message}" | /bin/mail -s "WebYaST Test Mail" '#{to}' -r root`

    unless File.directory? File.join(Paths::VAR,"mail")
      Rails.logger.debug "directory does not exists...."
      return
    end
    begin
      f = File.new(TEST_MAIL_FILE, 'w')
      f.puts "#{to}"
    rescue
      Rails.logger.error "writing #{TEST_MAIL_FILE} file failed - wrong permissions?"
    end
  end
end

require 'exceptions'
class MailError < BackendException

  def initialize(message)
    @message = message
    super("Mail setup failed with this error: #{@message}.")
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "MAIL_SETTINGS_ERROR"
      xml.description message
      xml.output @message
    end
  end
end
