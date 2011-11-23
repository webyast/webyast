class ApplicationController < ActionController::Base
  before_filter :authenticate_account!
  #protect_from_forgery
  before_filter :set_gettext_locale

  # This defines how the default Ability (for cancan, the
  # role based mechanism) is constructed
  def current_ability
    @current_ability ||= Ability.new(current_account)
  end
end

