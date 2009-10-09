# = Mail Settings controller
# For configuration of which SMTP server use for sending mails
class MailSettingsController < ApplicationController

  before_filter :login_required

  # GET action
  # Read mail settings
  # Requires read permissions for mail server YaPI.
  def show
    yapi_perm_check "mailsettings.read"

    @mail = MailSettings.instance
    @mail.read

    respond_to do |format|
      format.html { render :xml => @mail.to_xml(:root => "mail_settings"), :location => "none" } #return xml only
      format.xml  { render :xml => @mail.to_xml(:root => "mail_settings", :indent=>2), :location => "none" }
      format.json { render :json => @mail.to_json, :location => "none" }
    end
  end
   
  # PUT action
  # Write mail settings
  # Requires write permissions for mail server YaPI.
  def update
    yapi_perm_check "mailsettings.write"
	
    @mail = MailSettings.instance
    @mail.save(params["mail_settings"])
    show
  end

  def create
    update
  end
end
