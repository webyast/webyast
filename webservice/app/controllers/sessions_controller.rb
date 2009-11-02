#
# SessionsController
#
#
# This controller handles the login/logout function of the site.
#
# /login -> SessionsController.create
# /logout -> SessionsController.destroy
#
# and implements a 'session' resource
#
#
class SessionsController < ApplicationController

  # render new.rhtml
  def new
    redirect_back_or_default('/')
  end

  def show
    @ret = Hash.new
    @ret[:hash] = Hash.new
    @ret[:hash][:login] = 'nobody'
  end
  
  def create
    if params["hash"].is_a? Hash
      #checking if the session description is hosted in a own Hash
      params["hash"].each do |name,value|
         params[name] = value
      end
    end
    if params.has_key?(:login) && params[:password]
       self.current_account = Account.authenticate(params[:login], params[:password])
    end
    @cmd_ret = Hash.new
    if BruteForceProtection.instance.blocked?
      @cmd_ret["login"] = "blocked"
      @cmd_ret["remain"] = BruteForceProtection.instance.last_fail + BruteForceProtection::BAN_TIMEOUT
    elsif logged_in?
      if params[:remember_me]
        current_account.remember_me unless current_account.remember_token?
        cookies[:auth_token] = { :value => self.current_account.remember_token , :expires => self.current_account.remember_token_expires_at }
      end

      @cmd_ret["login"] = "granted"
      @cmd_ret["auth_token"] = { :value => self.current_account.remember_token , :expires => self.current_account.remember_token_expires_at }
    else
      @cmd_ret["login"] = "denied"
      BruteForceProtection.instance.fail_attempt
    end
  end

  def destroy
    self.current_account.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    @cmd_ret = Hash.new
    @cmd_ret["logout"] = "Goodbye!"
  end
end
