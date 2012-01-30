class SessionsController < Devise::SessionsController
  include FastGettext::Translation

  def initialize
    puts "Sessions"
    I18n.locale = FastGettext.locale
    super
  end

end
