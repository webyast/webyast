# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  # render new.rhtml
  def new
    redirect_back_or_default('/')
  end

  def create
    if params["hash"] != nil
      #checking if the session description is hosted in a own Hash
      params["hash"].each do |name,value|
         params[name] = value
      end
    end

    self.current_account = Account.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        current_account.remember_me unless current_account.remember_token?
        cookies[:auth_token] = { :value => self.current_account.remember_token , :expires => self.current_account.remember_token_expires_at }
      end

      @cmdRet = Hash.new
      @cmdRet["login"] = "granted"
      @cmdRet["auth_token"] = { :value => self.current_account.remember_token , :expires => self.current_account.remember_token_expires_at }
      respond_to do |format|
        format.xml do
	  render :xml => @cmdRet.to_xml, :location => "none"
        end
        format.json do
          render :json => @cmdRet.to_json, :location => "none"
        end
        format.html do
	  render :xml => @cmdRet.to_xml, :location => "none"
        end
      end
    else
      @cmdRet = Hash.new
      @cmdRet["login"] = "denied"
      respond_to do |format|
        format.xml do
	  render :xml => @cmdRet.to_xml, :location => "none"
        end
        format.json do
          render :json => @cmdRet.to_json, :location => "none"
        end
        format.html do
	  render :xml => @cmdRet.to_xml, :location => "none" #only XML will be returned
        end
      end
    end
  end

  def destroy
    self.current_account.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    @cmdRet = Hash.new
    @cmdRet["logout"] = "Goodbye!"
    respond_to do |format|
      format.xml do
	render :xml => @cmdRet.to_xml, :location => "none"
      end
      format.json do
        render :json => @cmdRet.to_json, :location => "none"
      end
      format.html do
	render :xml => @cmdRet.to_xml, :location => "none" #only XML will be returned
      end
    end
  end
end
