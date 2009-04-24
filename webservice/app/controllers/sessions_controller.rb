# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  # render new.rhtml
  def new
    redirect_back_or_default('/')
  end

  def show
    ret = Hash.new
    ret[:hash] = Hash.new
    ret[:hash][:login] = 'foo'
    respond_to do |format|
      format.xml { render :xml => ret.to_xml, :location => "none" }
      format.json { render :json => ret.to_json, :location => "none" }
      format.html { render :html => ret.to_xml, :location => "none" }
    end
  end
  
  def create
    if params["hash"] != nil
      #checking if the session description is hosted in a own Hash
      params["hash"].each do |name,value|
         params[name] = value
      end
    end
    if params.has_key?(:login) && params[:password]
       self.current_account = Account.authenticate(params[:login], params[:password])
    end
    if logged_in?
      if params.has_key?(:remember_me) && params[:remember_me] == true
        current_account.remember_me unless current_account.remember_token?
        cookies[:auth_token] = { :value => self.current_account.remember_token , :expires => self.current_account.remember_token_expires_at }
      end

      @cmd_ret = Hash.new
      @cmd_ret["login"] = "granted"
      @cmd_ret["auth_token"] = { :value => self.current_account.remember_token , :expires => self.current_account.remember_token_expires_at }
      respond_to do |format|
        format.xml do
	  render :xml => @cmd_ret.to_xml, :location => "none"
        end
        format.json do
          render :json => @cmd_ret.to_json, :location => "none"
        end
        format.html do
	  render :xml => @cmd_ret.to_xml, :location => "none"
        end
      end
    else
      @cmd_ret = Hash.new
      @cmd_ret["login"] = "denied"
      respond_to do |format|
        format.xml do
	  render :xml => @cmd_ret.to_xml, :location => "none"
        end
        format.json do
          render :json => @cmd_ret.to_json, :location => "none"
        end
        format.html do
	  render :xml => @cmd_ret.to_xml, :location => "none" #only XML will be returned
        end
      end
    end
  end

  def destroy
    self.current_account.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    @cmd_ret = Hash.new
    @cmd_ret["logout"] = "Goodbye!"
    respond_to do |format|
      format.xml do
	render :xml => @cmd_ret.to_xml, :location => "none"
      end
      format.json do
        render :json => @cmd_ret.to_json, :location => "none"
      end
      format.html do
	render :xml => @cmd_ret.to_xml, :location => "none" #only XML will be returned
      end
    end
  end
end
