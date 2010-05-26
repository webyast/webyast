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
# = Systemtime controller
# Provides access to time settings for authentificated users.
# Main goal is checking permissions.
class RolesController < ApplicationController

  before_filter :login_required

  #--------------------------------------------------------------------------------
  #
  # actions
  #
  #--------------------------------------------------------------------------------

  # Sets time settings. Requires write permissions for time YaPI.
  def update
		#TODO check if id exist
		role = Role.find(params[:id]).load(params[:roles])
    permission_check "org.opensuse.yast.roles.modify" if role.changed_permissions?
    permission_check "org.opensuse.yast.roles.assign" if role.changed_users?
    logger.info "update role #{params[:id]}. New record? #{role.new_record?}"
    role.save
		show
  end

  def create
		#TODO check if id do not exist
    permission_check "org.opensuse.yast.roles.modify"
		role = Role.new.load(params["roles"])
    permission_check "org.opensuse.yast.roles.assign" unless role.users.empty?
    role.save
		params[:id] = params["roles"]["name"]
		show
  end

	def delete
		#TODO check if id exist
    permission_check "org.opensuse.yast.roles.modify"
    permission_check "org.opensuse.yast.roles.assign" unless Role.find(params[:id]).users.empty?
		Role.delete params[:id]
		index
	end

  # Shows time settings. Requires read permission for time YaPI.
  def show
		role = Role.find params[:id]
		unless role
			#TODO raise exception
			raise InvalidParameters.new :id => "NONEXIST"
		end

    respond_to do |format|
      format.xml { render :xml => role.to_xml( :dasherize => false ) }
      format.json { render :json => role.to_json( :dasherize => false ) }
    end
  end

  def index
    #TODO check permissions
    roles = Role.find
    
    respond_to do |format|
      format.xml { render :xml => roles.to_xml( :dasherize => false ) }
      format.json { render :json => roles.to_json( :dasherize => false ) }
    end
  end

end
