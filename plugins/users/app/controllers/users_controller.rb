# import YastService class FIXME move into the model...

include ApplicationHelper

class UsersController < ApplicationController
  
  before_filter :login_required

  def initialize
  end

  # GET /users
  # GET /users.xml
  # GET /users.json
  def index
    unless permission_check("org.opensuse.yast.modules.yapi.users.usersget")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    @users = User.find_all
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    unless permission_check("org.opensuse.yast.modules.yapi.users.userget")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    if params[:id].blank?
      render ErrorResult.error(404, 2, "empty parameter") and return
    end

    begin
      # try to find the user, and 404 if it does not exist
      @user = User.find(params[:id])
      if @user.nil?
        render ErrorResult.error(404, 2, "user not found") and return
      end
    rescue Exception => e
      render ErrorResult.error(500, 2, e.message) and return
    end

  end


  # POST /users
  # POST /users.xml
  # POST /users.json
  def create
    unless permission_check("org.opensuse.yast.modules.yapi.users.useradd")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    begin
      @user = User.create(params[:users])
    rescue Exception => e
      render ErrorResult.error(404, @error_id, @error_string) and return
    end
    
    render :show
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    unless permission_check("org.opensuse.yast.modules.yapi.users.usermodify")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    if params[:users] && params[:users][:uid]
       params[:id] = params[:users][:uid] #for sync only
    end

    begin
      begin
        @user = User.find(params[:id])
      rescue Exception => e
        render ErrorResult.error(404, 2, e.message) and return
      end
      @user.load_attributes(params[:users])
      @user.save
    rescue Exception => e
      # FIXME here should be internal error I guess
      render ErrorResult.error(404, 2, e.message) and return
    end    
    render :show
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  # DELETE /users/1.json
  def destroy
    unless permission_check("org.opensuse.yast.modules.yapi.users.userdelete")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    begin
      @user = User.find(params[:id])
      @user.destroy
    rescue Exception => e
      render ErrorResult.error(404, @error_id, e.message) and return
    end
    render :show
  end

end

