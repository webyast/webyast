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
    else
      logger.warn "mail_settings hash missing in request"
    end
    show
  end

  def create
    update
  end
end
