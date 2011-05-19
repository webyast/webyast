#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

include ApplicationHelper

class UsersController < ApplicationController
  
  before_filter :login_required

  private

  def init_cache(controller_name = request.parameters["controller"])
    if params[:getent] == "1"
      super "getent_passwd"
    else
      super
    end
  end

  public

  def initialize
  end

  # GET /users
  # GET /users.xml
  # GET /users.json
  def index
    yapi_perm_check "users.usersget"
    if params[:getent] == "1"
      respond_to do |format|
        format.xml { render  :xml => GetentPasswd.find.to_xml }
        format.json { render :json => GetentPasswd.find.to_json }
      end
      return
    end
    @users = User.find_all params
    if @users.nil?
      Rails.logger.error "No users found."
      render ErrorResult.error(404, 2, "No users found") and return
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    yapi_perm_check "users.userget"
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
    yapi_perm_check "users.useradd"

    begin
      @user = User.create(params[:users])
    rescue Exception => e
      render ErrorResult.error(404, 2, e.message) and return
    end
    
    render :show
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    yapi_perm_check "users.usermodify"

    begin
      begin
        @user = User.find(params[:id])
      rescue Exception => e
        render ErrorResult.error(404, 2, e.message) and return
      end
      @user.load_attributes(params[:users])
      @user.save(params[:id])
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
    yapi_perm_check "users.userdelete"

    begin
      @user = User.find(params[:id])
      @user.destroy
    rescue Exception => e
      render ErrorResult.error(404, @error_id, e.message) and return
    end
    render :show
  end

end

