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

class GroupsController < ApplicationController
  
  before_filter :login_required

  before_filter :check_read_permission, :only => [:index,:show]
  before_filter :check_write_permission, :only => [:create, :update]

private

  def check_read_permission
    yapi_perm_check "users.groupsget"
    yapi_perm_check "users.groupget"
  end

  def check_write_permission
    yapi_perm_check "users.groupmodify"
    yapi_perm_check "users.groupadd"
  end

  # log Group.find error and provide matching ErrorResult
  def group_not_found gid
    Rails.logger.error "Group #{gid} was not found."
    ErrorResult.error(404, 2, "group #{gid} not found")
  end
  
public

  # GET /groups/users
  # GET /groups/users.xml
  def show
    # try to find the grouplist, and 404 if it does not exist
    @group = Group.find params[:id]
    if @group.nil?
      render group_not_found(params[:id]) and return
    end

    respond_to do |format|
      format.xml { render  :xml => @group.to_xml( :dasherize => false ) }
      format.json { render :json => @group.to_json }
    end
  end

  # GET /groups.xml
  def index
    # read permissions were checked in a before filter
    @groups = Group.find_all
    @groups.sort! {|x,y| x.cn <=> y.cn}
    if @groups.nil?
      Rails.logger.error "No groups found."
      render ErrorResult.error(404, 2, "No groups found") and return
    end

    respond_to do |format|
      format.xml { render  :xml => @groups.to_xml(:root => "groups", :dasherize => false ) }
      format.json { render :json => @groups.to_json }
    end
  end

  # POST /groups/users/
  def update
    group_params = params[:groups] || {}
    group_params[:old_cn] = params[:id]
    @group = Group.new group_params
    result = @group.save
    unless result.empty?
      render ErrorResult.error(404, 2, "Group update error:'"+result+"'") and return
    end
    render :show
  end

  # PUT /groups/
  def create
    group_params = params[:groups] || {}
    group_params[:old_cn] = group_params[:cn]
    @group = Group.new group_params

    result = @group.save
    unless result.empty?
      render ErrorResult.error(404, 2, "Group create error:'"+result+"'") and return
    end
    render :show
  end

  # DELETE /groups/users
  def destroy
    yapi_perm_check "users.groupdelete"

    @group = Group.find(params[:id])

    if @group.nil?
      render group_not_found(params[:id]) and return
    end

    result = @group.destroy
    unless result.empty?
      render ErrorResult.error(404, 2, "Cannot remove group #{@group.cn}: #{result}") and return
    end

    render :show
  end
end
