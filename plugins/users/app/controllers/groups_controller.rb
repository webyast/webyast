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

public

  # GET /groups/users
  # GET /groups/users.xml
  def show
    begin
      # try to find the grouplist, and 404 if it does not exist
      @group = Group.find params[:id]
      if @group.nil?
        render ErrorResult.error(404, 2, "grouplist not found") and return
      end
    rescue Exception => e
      render ErrorResult.error(500, 2, e.message) and return
    end

    respond_to do |format|
      format.xml { render  :xml => @group.to_xml( :dasherize => false ) }
      format.json { render :json => @group.to_json }
    end
  end

  # GET /groups.xml
  def index
    # read permissions were checked in a before filter
    begin
      @groups = Group.find_all
    rescue DBus::Error => exception
      render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
    end

    respond_to do |format|
      format.xml { render  :xml => @groups.to_xml(:root => "groups", :dasherize => false ) }
      format.json { render :json => @groups.to_json }
    end
  end

  # POST /groups/users/
  def update
    group_params = params[:groups] || {}
    group_params[:old_gid] = params[:id]
    @group = Group.new group_params
    begin
      result = @group.save
      unless result.empty?
        render ErrorResult.error(404, 2, "Group update error:'"+result+"'") and return
      end
    rescue DBus::Error => exception
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
    end
    render :show
  end

  # PUT /groups/
  def create
    group_params = params[:groups] || {}
    group_params[:old_gid] = group_params[:gid]
    @group = Group.new group_params
    begin
      result = @group.save
      unless result.empty?
        render ErrorResult.error(404, 2, "Group create error:'"+result+"'") and return
      end
    rescue DBus::Error => exception
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
    end
    render :show
  end

  # DELETE /groups/users
  def destroy
    yapi_perm_check "users.groupdelete"

    begin
      @group = Group.find(params[:id])
    rescue DBus::Error => exception
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
    end

    if @group.nil?
      Rails.logger.error "Group #{params[:id]} was not found."
      render ErrorResult.error(404, 1, "Group '#{params[:id]}' not found.") and return
    end

    begin
      result = @group.destroy
      unless result.empty?
        render ErrorResult.error(404, 2, "Cannot remove group #{@group.cn}: #{result}") and return
      end
    rescue DBus::Error => exception
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
    end

    render :show
  end
end

