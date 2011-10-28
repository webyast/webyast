class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_gettext_locale
end

