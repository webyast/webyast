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

require 'digest/sha2'

class MailsettingController < ApplicationController

  layout 'main'

  # Initialize GetText and Content-Type.
  FastGettext.add_text_domain "webyast-mail", :path => "locale"
  
  public

  def index
    authorize! :read, Mailsetting
   
    @mail = Mailsetting.find
    @mail.confirm_password	= @mail.password
    @mail.test_mail_address	= ""
    @mail.test_mail_address	= params["email"] if params.has_key? "email"
    @mail.smtp_server = @mail.smtp_server.gsub(/^(\[)|(\])/, '') unless @mail.smtp_server.nil? #remove square brackets from smtp_server string
  end
  
  def show
    authorize! :read, Mailsetting
    mail = Mailsetting.find

    respond_to do |format|
      format.xml  { render :xml => mail.to_xml(:root => "mail", :dasherize => false, :indent=>2), :location => "none" }
      format.json { render :json => mail.to_json, :location => "none" }
    end
  end
    
  def update
    authorize! :write, Mailsetting
    @mail = Mailsetting.find
    @mail.load params["mail"]

    # validate data also here, if javascript in view is off
    if @mail.password != @mail.confirm_password
      flash[:error] = _("Passwords do not match.")
      redirect_to :action => "index"
      return
    end

    begin
      response = @mail.save
      notice = _('Mail settings have been written.')
      unless @mail.test_mail_address.blank?
        notice += " " + _('Test mail was sent to %s.') % @mail.test_mail_address
      end
      flash[:notice] = notice
      
      rescue ActiveResource::ClientError => e
        flash[:error] = YaST::ServiceResource.error(e)
        logger.warn e.inspect
        redirect_to :action => "index"
        return
          
      rescue ActiveResource::ServerError => e
        error = Hash.from_xml e.response.body
        logger.warn error.inspect
        if error["error"] && error["error"]["type"] == "MAIL_SETTINGS_ERROR"
          flash[:error] = _("Error while saving mail settings: %s") % error["error"]["output"]
        else
          raise e
        end
      
        redirect_to :action => "index"
        return
      end

      smtp_server	= params["mail"]["smtp_server"]

      # check if mail forwarning for root is configured
      # during initial workflow, only warn if administrator configuration does not follow
      if smtp_server.blank? && (!Basesystem.new.load_from_session(session).following_steps.any? { |h| h[:controller] == "administrator" })
        @administrator      = Administrator.find
      
        if @administrator && !@administrator.aliases.blank?
          flash[:warning]	= _("No outgoing mail server is set, but administrator has mail forwarders defined.
          Change %s<i>administrator</i>%s or %s<i>mail</i>%s configuration.") % ['<a href="/administrator">', '</a>', '<a href="/mail">', '</a>']
        end
      end
      
      if params.has_key?("send_mail")
        redirect_to :action => "index", :email => params["mail"]["test_mail_address"]
        return
      end
      redirect_success # redirect to next step
  end
  
  def create
    update
  end
end

