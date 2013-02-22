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

# = Mail controller
# For configuration of which SMTP server use for sending mails

class MailsettingController < ApplicationController

  rescue_from Timeout::Error do |error|
    respond_to do |format|
      format.json { render :json => { :message => error.message }, :status => 400 }
      format.xml  { render :xml  => { :message => error.message }, :status => 400 }
    end
  end

  def show
    authorize! :read, Mailsetting

    @mail = Mailsetting.find
    @mail.password_confirmation	= @mail.password
    @mail.test_mail_address	= ""
    @mail.test_mail_address	= params["email"] if params.has_key? "email"
    @mail.smtp_server = @mail.smtp_server.gsub(/^(\[)|(\])/, '') unless @mail.smtp_server.nil? #remove square brackets from smtp_server string

    respond_to do |format|
      format.html
      format.xml  {
        if @mail
          render :xml => @mail.to_xml(:dasherize => false, :root => "mail", :location => "none")
        else
          head :not_found
        end
      }
      format.json {
        if @mail
          render :json => @mail.to_json, :location => "none"
        else
          head :not_found
        end
      }
    end
  end

  def update
    authorize! :write, Mailsetting
    mail_params = params[:mailsetting] || params[:mail] #keep mail for backwards compatibility with old REST API
    @mail = Mailsetting.find
    @mail.load mail_params

    unless @mail.valid?
      problem _(@mail.errors.full_messages.join(', '))
      return
    end

    begin
      response = @mail.save
      notice = _('Mail settings have been written.')
      unless @mail.test_mail_address.blank?
        @mail.send_test_mail
        notice += " " + _('Test mail was sent to %s.') % @mail.test_mail_address
      end
      flash[:notice] = notice

    rescue Exception => error
      problem _("Error while saving mail settings. #{error.message}")
      Rails.logger.error "ERROR: #{error.message}"
      return
    end

    smtp_server = mail_params["smtp_server"]

    # check if mail forwarning for root is configured
    # during initial workflow, only warn if administrator configuration does not follow
    if smtp_server.blank? && (!Basesystem.new.load_from_session(session).following_steps.any? { |h| h[:controller] == "administrator" })
      @administrator = Administrator.find

      if @administrator && !@administrator.aliases.blank?
        flash[:warning]	= _("No outgoing mail server is set, but administrator has mail forwarders defined.
        Change %s<i>administrator</i>%s or %s<i>mail</i>%s configuration.") % ['<a href="/administrator">', '</a>', '<a href="/mail">', '</a>']
      end
    end

    if request.format.html?
      redirect_success # redirect to next step
    else
      redirect_to :back
    end
  end

  def create
    update
  end

  def send_test_mail
    smtp_server, port = params[:mailsetting][:smtp_server].split(':')
    settings = {
      :server   => smtp_server,
      :port     => (port || 25).to_i,
      :to       => params[:mailsetting][:test_mail_address],
      :tls      => params[:mailsetting][:transport_layer_security] == 'no' ? false : true,
      :hostname => request.host,
      :domain   => request.domain,
      :user     => params[:mailsetting][:user],
      :password => params[:mailsetting][:password]
    }
    MailsettingNotifier.server_settings   settings
    email = MailsettingNotifier.test_mail settings
    email.deliver
  rescue => error
    Rails.logger.error error.message
  ensure
    if error.present?
      render :json => { :message => _("Sending of email failed. #{error.message}") }, :status => 400
    else
      render :json => { :message => _("Email has been sent") }, :status => 200
    end
  end

private

  def problem message
    if request.format.html?
      flash[:error] = message
      redirect_to :back
    else #REST request
      error = { "error" => { "type" => "ADMINISTRATOR_ERROR", "messsage" => message, "id" => "ADMINISTRATOR" }}
      respond_to do |format|
        format.xml  { render :xml => error, :status => 400 }
        format.json { render :json => error, :status => 400 }
      end
    end
  end
end

