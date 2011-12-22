
class ApplicationController < ActionController::Base

  before_filter :authenticate_account!
  #protect_from_forgery
  before_filter :set_gettext_locale

  # This defines how the default Ability (for cancan, the
  # role based mechanism) is constructed
  def current_ability
    @current_ability ||= Ability.new(current_account)
  end

protected
  def redirect_success
    logger.debug session.inspect
    if Basesystem.new.load_from_session(session).in_process?
      logger.debug "wizard redirect DONE"
      redirect_to :controller => "/controlpanel", :action => "nextstep", :done => self.controller_name
    else
      logger.debug "Success non-wizard redirect"
      redirect_to :controller => "/controlpanel", :action => "index"
    end
  end

end

