class SessionsController < Devise::SessionsController
  include FastGettext::Translation

  def initialize
    I18n.locale = FastGettext.locale
    super
  end

end
