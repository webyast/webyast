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

require 'yast/paths'
require 'base'
require 'builder'

# = Mailsetting model
# Proviceds access local mail settings (SMTP server to use)
# Uses YaPI::MailSettings for read and write operations,
# YaPI::SERVICES, for reloading postfix service.
class Mailsetting < BaseModel::Base

  attr_accessor :smtp_server
  attr_accessor :user
  attr_accessor :password
  attr_accessor :password_confirmation
  attr_accessor :test_mail_address
  attr_accessor :transport_layer_security


  validates :smtp_server, :presence=>true
  validates :user,        :presence=>true
  validates :password,    :presence=>true, :confirmation=>true
  validates :password_confirmation,    :presence=>true
  validates :transport_layer_security, :presence=>true

  validate :email_address_format

  TEST_MAIL_FILE = File.join(YaST::Paths::VAR,"mailsetting","test_sent")
  CACHE_ID = "webyast_mailsetting"
  EMAIL_FORMAT_PATTERN = /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/

  # read the settings from system
  def self.find
    Rails.cache.fetch(CACHE_ID) do
      yapi_ret = YastService.Call("YaPI::MailSettings::Read")
      raise MailError.new("Cannot read from YaPI backend") if yapi_ret.nil?
      yapi_ret["transport_layer_security"] = yapi_ret.delete("TLS") || "no"
      Mailsetting.new yapi_ret
    end
  end


  # Save new mail settings
  def update

    parameters	= {
	"smtp_server"	=> [ "s", smtp_server ||""],
	"user"		=> [ "s", user ||""],
	"password"	=> [ "s", password ||""],
	"TLS"		=> [ "s", transport_layer_security ||""]
    }

    Rails.cache.delete(CACHE_ID)

    yapi_ret = YastService.Call("YaPI::MailSettings::Write", parameters)
    Rails.logger.debug "YaPI returns: '#{yapi_ret}'"

    raise MailError.new(yapi_ret) unless yapi_ret.empty?
    true
  end

  def self.valid_mail_address? (address)
    return !!address.match(EMAIL_FORMAT_PATTERN)
  end

  def self.send_test_mail(to)
    return if to.blank?

    Rails.logger.debug "sending test mail to #{to}..."

    message	= "This is the test mail sent to you by webYaST."

    # remove potential problematic characters from email address
    raise "Invalid email address" unless valid_mail_address?(to)
    `/bin/echo "#{message}" | /bin/mail -s "WebYaST Test Mail" '#{to}' -r root`

    mail_directory = File.join(YaST::Paths::VAR,"mailsetting")
    unless File.directory? mail_directory
      Rails.logger.debug "Directory #{mail_directory} does not exists"
      return
    end
    begin
      File.open TEST_MAIL_FILE, 'w' do |file|
        file.puts to.to_s
      end
    rescue => error
      Rails.logger.error e
    end
  end

  def send_test_mail
    self.class.send_test_mail test_mail_address
  end

  private

  def email_address_format
    if test_mail_address.present?
      errors.add :test_mail_address, _("is not valid") unless test_mail_address.match(EMAIL_FORMAT_PATTERN)
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

class MailsettingNotifier < ActionMailer::Base
  def self.server_settings options
    from = "root@#{options[:hostname]}"
    self.default :from => from, :return_path => from
    self.smtp_settings = {
      :address   => options[:server],
      :port      => options[:port],
      :user_name => options[:user],
      :password  => options[:password],
      :domain    => options[:domain],
      :enable_starttls_auto => options[:tls],
      :authentication => :login,
      :openssl_verify_mode => OpenSSL::SSL::VERIFY_NONE
    }

    self.delivery_method       = :smtp
    self.perform_deliveries    = true
    self.raise_delivery_errors = true
  end

  def test_mail options
    @from     = "root@#{options[:hostname]}"
    @to       = options[:to]
    @subject  = "WebYaST Test Mail"
    @sent_at  = Time.new.strftime "%Y-%m-%d %H-%M-%S"
    @hostname = options[:hostname]
    mail :to => @to, :subject => @subject, :from => @from,
         :template_name => 'test_mail', :template_path => 'mailsetting',
         :content_type => 'text/html'
  end
end
