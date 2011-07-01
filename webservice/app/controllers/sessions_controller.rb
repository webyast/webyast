#--
# Webyast Webservice framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++


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
  layout 'main'

  def index
    redirect_to "/"
  end

  def show
    #FIXME this is cryptic. @ret = { :hash => { :login => 'nobody' } } but do we need so complex hash and why set nobody ENODOC!
    @ret = Hash.new
    @ret[:hash] = Hash.new
    @ret[:hash][:login] = 'nobody'
    respond_to do |format|
      format.html { redirect_to "/" }
      format.json {}
      format.xml {}
    end
  end

  #
  # Start new session
  #  render login screen
  #
  def new
    # Set @host to display info at login screen
    @host = "localhost"

    # render login screen, asking for username/password
  end
  
  def create
    #FIXME XXX tom: also reset_session here to fix possible session fixation attack etc.
    if params["hash"].is_a? Hash #FIXME report that "hash" value is not hash
      #checking if the session description is hosted in a own Hash
      params["hash"].each do |name,value|
         params[name] = value
      end
    end
    if request.format.html?
      if params[:login].blank?
        flash[:warning] = _("No login specified")
        redirect_to :action => "new"
      elsif params[:password].blank?
        flash[:warning] = _("No password specified")
        redirect_to :action => "new", :login => params[:login]
      end
    end

    if params.has_key?(:login) && params[:password]
       ip = params[:ip] || request.remote_ip
       self.current_account = Account.authenticate(params[:login], params[:password], ip)
    end
    @cmd_ret = Hash.new
    if BruteForceProtection.instance.blocked? params[:login]
      @cmd_ret["login"] = "blocked"
      @cmd_ret["remain"] = BruteForceProtection.instance.last_failed(params[:login]) + BruteForceProtection::BAN_TIMEOUT
    elsif logged_in?
      if params[:remember_me] || request.format.html?
        current_account.remember_me unless current_account.remember_token?
        cookies[:auth_token] = { :value => self.current_account.remember_token , :expires => self.current_account.remember_token_expires_at }
      end

      @cmd_ret["login"] = "granted"
      @cmd_ret["auth_token"] = { :value => self.current_account.remember_token , :expires => self.current_account.remember_token_expires_at }
      logger.info "Login success."
      respond_to do |format|
        format.html { redirect_back_or_default("/") }
        format.json {}
        format.xml {}
      end
      
    else
      logger.warn "Login failed from ip #{request.remote_ip} with user #{params[:login] ||""}"
      @cmd_ret["login"] = "denied"
      BruteForceProtection.instance.fail_attempt params[:login]
      respond_to do |format|
        format.html { 
          flash[:warning] = _("Login incorrect. Check your username and password.")
          redirect_to :action => "new"
        }
        format.json {}
        format.xml {}
      end
    end

  end

  def destroy
    self.current_account.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session # RORSCAN_ITL
    @cmd_ret = Hash.new
    @cmd_ret["logout"] = "Goodbye!"
    respond_to do |format|
      format.html { 
        # reset_session clears all flash messages, make a backup before the call
        flash_backup = flash

        reset_session # RORSCAN_ITL

        # restore the values from backup
        flash.replace(flash_backup)

        flash[:notice] = _("You have been logged out.") unless flash[:notice]
        redirect_to :controller => "session", :action => "new"
      }
      format.json {}
      format.xml {}
    end
  end
end
