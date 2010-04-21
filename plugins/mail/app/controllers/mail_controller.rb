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
class MailController < ApplicationController

  before_filter :login_required

  # GET action
  # Read mail settings
  # Requires read permissions for mail server YaPI.
  def show
    yapi_perm_check "mailsettings.read"

    @mail = Mail.instance
    @mail.read

    respond_to do |format|
      format.xml  { render :xml => @mail.to_xml(:root => "mail", :dasherize => false, :indent=>2), :location => "none" }
      format.json { render :json => @mail.to_json, :location => "none" }
    end
  end
   
  # PUT action
  # Write mail settings
  # Requires write permissions for mail server YaPI.
  def update
    yapi_perm_check "mailsettings.write"

    @mail = Mail.instance
    @mail.read
    if params.has_key? "mail"
      @mail.save(params["mail"])
      if params["mail"].has_key?("test_mail_address")
	@mail.send_test_mail(params["mail"]["test_mail_address"])
      end
    else
      logger.warn "mail hash missing in request"
    end
    show
  end

  def create
    update
  end
end
