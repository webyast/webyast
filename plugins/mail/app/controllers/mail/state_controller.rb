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

# = Mail::State controller
# Confirm that an test email has been sent

class Mail::StateController < ApplicationController

  before_filter :login_required
   
  # PUT action
  # Confirm that an test email has been sent
  def update
    yapi_perm_check "mailsettings.write"

    logger.warn "Confirmation of testmail"
    File.delete Mail::TEST_MAIL_FILE if File.exist? Mail::TEST_MAIL_FILE

    mail = Mail.find
    respond_to do |format|
      format.xml  { render :xml => mail.to_xml(:root => "mail", :dasherize => false, :indent=>2), :location => "none" }
      format.json { render :json => mail.to_json, :location => "none" }
    end
  end

  # POST action
  def create
    update
  end
end
