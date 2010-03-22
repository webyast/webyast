include ApplicationHelper

class GroupsController < ApplicationController
  
  before_filter :login_required

  before_filter :check_read_permissions, :only => [:index,:show]
  before_filter :check_write_permissions, :only => [:create, :update]

private:

  def check_read_permission
    yapi_perm_check "users.groupsget"
  end

  def check_write_permission
    yapi_perm_check "users.groupsmodify"
  end

public:

  # GET /groups/1
  # GET /groups/1.xml
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

  # POST /groups/1/
  def update
    group_params = params[:groups] || {}
    group_params[:old_gid] = params[:id]
    group = Group.new group_params
    group.save
  end

  # PUT /groups/
  def create
    group_params = params[:groups] || {}
    group_params[:old_gid] = group_params[:gid]
    group = Group.new group_params
    group.save
  end
end

