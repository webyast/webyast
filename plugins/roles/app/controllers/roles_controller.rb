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

  before_filter :login_required
  before_filter :check_role_name, :only => [:delete, :show]
  before_filter :check_read_permission
  before_filter :check_write_permission, :only => [:update,:delete] 

  layout 'main'

  # Initialize GetText and Content-Type.
  init_gettext "webyast-roles"

  def check_write_permission
    permission_check("org.opensuse.yast.permissions.write") #goes back to controllcenter if not
  end
  def check_read_permission
    permission_check("org.opensuse.yast.permissions.read") #goes back to controllcenter if not
    @write_permission = permission_granted?("org.opensuse.yast.permissions.write")
  end

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
  # Parameters: {"id"=>"tester2", "roles"=>{"name"=>"tester2", "id"=>"tester2", "users"=>[], 
  #                                         "permissions"=>["org.opensuse.yast.modules.yapi.firewall.read", 
  #                                                         "org.opensuse.yast.modules.yapi.firewall.write"]}}
  # VIA UI (JavaScript):
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
    unless params[:roles].nil? #REST interfce
      check_role_name
      role = Role.find(params[:id])
      raise InvalidParameters.new(:id => "NONEXIST") if role.nil?
      role.load(params[:roles])
      logger.info "update role #{params[:id]}. New record? #{role.new_record?}"
      role.save
      show
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
        format.xml  { render :xml => Role.new.to_xml( :dasherize => false ) }
        format.json { render :json => Role.new.to_json( :dasherize => false ) }
        format.html { redirect_to :action => :index }
      end
    end
  end

  # Create new role. 
  def create
    error = nil
    begin
      check_role_name params[:role_name]
    rescue Exception => error
      logger.error "Wrong role name"
      respond_to do |format|
        format.xml  { raise error }
        format.json { raise error }
        format.html { flash[:warning] = _("Role name is invalid. Allowed is combination of a-z, A-Z, numbers, space, dash and underscore only.")
                      redirect_to "/roles/" }
      end
    end
    role = Role.find(params[:role_name])
    unless role.nil? #role already exists
      respond_to do |format|
        format.xml  { raise InvalidParameters.new(:id => "EXIST") }
        format.json { raise InvalidParameters.new(:id => "EXIST") }
        format.html { flash[:warning] = _("Role name is already used.")
                      redirect_to "/roles/" }
      end
    end

    role = Role.new(params[:role_name])
    role.save
    respond_to do |format|
      format.xml { render :xml => role.to_xml( :dasherize => false ) }
      format.json { render :json => role.to_json( :dasherize => false ) }
      format.html { redirect_to "/roles/" }
    end
  end

  # Deletes roles.
  def destroy
    Role.delete params[:id]
    flash[:notice] = _("Role <i>%s</i> was successfully removed.") % params[:id] if request.format.html?
    index
  end

  # shows information about role with name.
  def show
    role = Role.find params[:id]
    unless role
      raise InvalidParameters.new :id => "NONEXIST"
    end

    respond_to do |format|
      format.xml { render :xml => role.to_xml( :dasherize => false ) }
      format.json { render :json => role.to_json( :dasherize => false ) }
    end
  end

  # Shows all roles
  def index
    @roles = Role.find
    
    respond_to do |format|
      format.xml  { render :xml => @roles.to_xml( :dasherize => false ) }
      format.json { render :json => @roles.to_json( :dasherize => false ) }
      format.html {
                    @roles.sort! {|r1,r2| r1.name <=> r2.name}
                    all_permissions = Permission.find :all, { :with_description => "1" }
                    all_permissions = all_permissions.collect {|p| PrefixedPermission.new(p[:id], p[:description])}
                      # create an [[key,value]] array of prefixed permissions, where key is the prefix
                      @prefixed_permissions = PrefixedPermissions.new(all_permissions).sort
                      @users =  GetentPasswd.find.collect {|u|
                      if u.respond_to?('full_name')
                        [u.login, u.full_name ]
                      else
                        [u.login, "" ]
                      end
                    }.sort
                    render :index
                  }
    end
  end

  private
  def check_role_name(id=params[:id])
    raise InvalidParameters.new(:id => "INVALID") if id.nil? or id.match(/^[a-zA-Z0-9_\-. ]+$/).nil?
  end
end
