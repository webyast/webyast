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

require 'exceptions'
# = Roles controller
# Provides access to roles settings for authentificated users.
# Main goal is checking permissions, validate id and pass request to model.
class RolesController < ApplicationController

  before_filter :check_read_permission
  before_filter :check_write_permission, :only => [:update,:delete]

  rescue_from InvalidParameters do |error|
    respond_to do |format|
      format.html do
        flash[:error] = error.message
        redirect_to :action => :index
      end
      format.xml  { render :xml => error,  :status => 400 }
      format.json { render :json => error, :status => 400 }
    end
  end

  private

  def check_role_param
    raise InvalidParameters.new _("Missing parameter 'role'") unless params[:role]
  end

  def check_role_name_uniqueness
    raise InvalidParameters.new _("Role name already exists") if Role.find params[:role][:name]
  end

  def check_role_valid
    raise InvalidParameters.new role.errors.full_messages.join unless @role.valid?
  end

  def check_role_exists
    role_name = params[:id]
    raise InvalidParameters.new _("Role with name '#{role_name}' does not exist.") unless Role.find(role_name)
  end

  def check_write_permission
    authorize! :write, Role #goes back to controllcenter if not
  end

  def check_read_permission
    authorize! :read, Role #goes back to controllcenter if not
  end

public

  def self.users_role_id (role_id)
    "users_of_" + role_id.gsub(/ /,"_") #replace space which cannot be in id - http://www.w3.org/TR/html4/types.html#type-name
  end

  def self.permission_role_id (permission_id, role_id)
    permission_id + ":permission_of:" + role_id
  end

  #--------------------------------------------------------------------------------
  #
  # actions
  #
  #--------------------------------------------------------------------------------

  # Update role. Requires modify permissions
  #
  # There are two kind of parameters while an update call:
  #
  # REST:
  # Parameters: {"role"=>{"name"=>"tester2", "users"=>[],
#                "permissions"=>["org.opensuse.yast.modules.yapi.firewall.read",
#                "org.opensuse.yast.modules.yapi.firewall.write"]}}
  # WEB-UI:
  # Parameters: {"org.opensuse.yast.modules.yapi.firewall.write:permission_of:tester2"=>"1",
  #              "org.opensuse.yast.modules.yapi.kerberos:permission_of:tester"=>"1",
  #              "users_of_tester2"=>"",
  #              "org.opensuse.yast.modules.yapi.firewall:permission_of:tester2"=>"1",
  #              "org.opensuse.yast.modules.yapi.kerberos.write:permission_of:tester"=>"1",
  #              "users_of_tester"=>"",
  #              "org.opensuse.yast.modules.yapi.firewall.read:permission_of:tester2"=>"1",
  #              "org.opensuse.yast.modules.yapi.kerberos.read:permission_of:tester"=>"1"}
  #

  def update
    if params[:role] #REST interfce
      check_role_exists
      check_role_name_uniqueness
      # RORSCAN_INL: Is not a Information Exposure cause all data can be read (indepent from user)
      @role = Role.find params[:id]
      @role.users = params[:role][:users] || []
      @role.permissions = params[:role][:permissions] || []
      check_role_valid
      @role.save
      respond_to do |format|
        format.xml  { render :xml =>  @role }
        format.json { render :json => @role }
      end
    else #JavaScript
      all_permissions = Permission.find(:all).collect {|p| p[:id] }
      changed_roles = []

      Role.find(:all).each do |role|
        new_permissions = all_permissions.find_all do |perm|
          params[RolesController.permission_role_id perm, role.name]
        end
        new_users = []
        new_users = params[RolesController.users_role_id role.name].split(",") unless params[RolesController.users_role_id role.name].blank?
        if new_permissions.sort != role.permissions.sort || new_users.sort != role.users.sort then
          role.permissions = new_permissions
          role.users = new_users
          changed_roles << role
        end
      end
      changed_roles.each {|role| role.save }
      respond_to do |format|
        format.html do
          flash[:notice] = _("Roles have been updated")
          redirect_to :action => :index
        end
      end
    end
  end

  # Create new role.
  # FIXME it is possible to create a role with non-existent user
  def create
    # RORSCAN_INL: Protected by attr_accessible in Role model
    check_role_param
    check_role_name_uniqueness
    @role = Role.new.load params[:role]
    check_role_valid
    @role.save
    respond_to do |format|
      format.xml  { render :xml =>  @role.to_xml( :dasherize => false )  }
      format.json { render :json => @role.to_json( :dasherize => false ) }
      format.html do
        flash[:notice] = _("Role '#{@role.name}' has been created")
        redirect_to :action => :index
      end
    end
  end

  # Deletes roles.
  # FIXME problem is that webui uses different parameters as the rest api
  # can use; the same is valid for the update action where an array of params
  # is being passed from web-ui which is hard acceptable in the rest api
  def destroy
    # RORSCAN_INL: User has already write permission for ALL roles here
    check_role_exists
    role_name = params[:id]
    Role.delete role_name
    respond_to do |format|
      format.html do
        flash[:notice] = _("Role \'%s\' was successfully removed.") % role_name
        redirect_to :action => :index
      end
      format.xml  { render :nothing => true, :status => 204 }
      format.json { render :nothing => true, :status => 204 }
    end
  end

  def show
    # RORSCAN_INL: User has already write permission for ALL roles here
    check_role_exists
    @role = Role.find params[:id]
    # no need for html format as only index is being rendered
    respond_to do |format|
      format.xml  { render :xml => @role.to_xml( :dasherize => false ) }
      format.json { render :json => @role.to_json( :dasherize => false ) }
    end
  end

  def index
    @roles = Role.find
    respond_to do |format|
      format.xml  { render :xml => @roles.to_xml( :dasherize => false ) }
      format.json { render :json => @roles.to_json( :dasherize => false ) }
      format.html do
        @roles.sort! {|r1,r2| r1.name <=> r2.name}
        all_permissions = Permission.find :all, { :with_description => "1" }
        all_permissions = all_permissions.collect {|p| PrefixedPermission.new(p[:id], p[:description])}
          # create an [[key,value]] array of prefixed permissions, where key is the prefix
          @prefixed_permissions = PrefixedPermissions.new(all_permissions).sort
          @users =  GetentPasswd.find.collect do |user|
            if user.respond_to?('full_name')
              [user.login, user.full_name ]
            else
              [user.login, "" ]
            end
          end.sort
        render :index
      end
    end
  end

end

