ActionController::Routing::Mapper.class_eval do
  protected
    alias_method :devise_unix2_chkpwd_authenticatable, :devise_session
end
