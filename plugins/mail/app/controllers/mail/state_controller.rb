# = Mail::State controller
# Confirm that an test email has been sent

class Mail::StateController < ApplicationController

  before_filter :login_required
   
  # PUT action
  # Confirm that an test email has been sent
  def update
    yapi_perm_check "mailsettings.write"

    logger.warn "Confirmation of testmail"
    File.delete Mail::TEST_MAIL_FILE

    @mail = Mail.instance
    respond_to do |format|
      format.xml  { render :xml => @mail.to_xml(:root => "mail", :dasherize => false, :indent=>2), :location => "none" }
      format.json { render :json => @mail.to_json, :location => "none" }
    end
  end

  # POST action
  def create
    update
  end
end
