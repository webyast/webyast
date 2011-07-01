#--
# Webyast framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++


#
# Configure PolicyKit permissions for a user
#

class PermissionsController < ApplicationController

  before_filter :login_required

  # before filter is called even when the action is cached
  before_filter :check_perms, :cache_valid, :only => :show

  # modify the cache path so it includes also the filter and user name parameters
  caches_action :show, :cache_path => Proc.new { |controller|
      ret = controller.controller_path
      unless controller.params[:user_id].blank?
        ret = ret + '/' + controller.params[:user_id]
      end
      unless controller.params[:filter].blank?
        ret = ret + '/' + controller.params[:filter]
      end
      if controller.params[:with_description]
        ret = ret + '/with_description'
      end
      Rails.logger.info "Using cache path: #{ret}"
      ret
  }

  CACHE_ID = 'permissions:timestamp'

  def initialize
    @permissions = []
  end
  
  private
  
  #
  # check if logged in user requests his own stuff
  #
  def user_self( params )
    !params[:user_id].blank? && (params[:user_id] == self.current_account.login)
  end

  def check_perms
    unless user_self(params)
      permission_check "org.opensuse.yast.permissions.read"
    end
  end

  def get_cache_timestamp
    lst = [
      # the global config file
      File.mtime('/etc/PolicyKit/PolicyKit.conf'),
      # policies
      File.mtime('/usr/share/PolicyKit/policy/'),
      # explicit user authorizations
      File.mtime('/var/lib/PolicyKit/'),
      # default overrides
      File.mtime('/var/lib/PolicyKit-public/'),
    ]

    lst.compact!

    lst.max.to_i
  end

  def cache_valid
 #cache contain string as it is only object supported by all caching backends
    cache_timestamp = Rails.cache.read(CACHE_ID).to_i
    current_timestamp = get_cache_timestamp

    if !cache_timestamp
        Rails.cache.write(CACHE_ID, current_timestamp.to_s)
    elsif cache_timestamp < current_timestamp
        Rails.logger.debug "#### Permissions cache expired"
        # expire all cached values using a regexp (for all users/filters)
        expire_fragment(%r{#{controller_path}/.*})
        Rails.cache.write(CACHE_ID, current_timestamp.to_s)
    end
  end

  public
#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------

  # permissions
  # GET /permissions/:user_id(.:format)

  def show
    # note: permission check is done in the check_perms before filter
    permission = Permission.find(:all,params)
    respond_to do |format|
      format.json { render :json => permission.to_json }
      format.xml { render :xml => permission.to_xml(:root => "permissions") }
    end
  end

  # change permissions
  # PUT /permissions/:id(.:format)
  # nested within users
  # PUT /users/:user_id/permissions/:id(.:format)

  def update

  #implementation is wrong so mark as not implemented
  ret = { :error => "not implemented" }
    respond_to do |format|
      format.json { render :json => ret.to_json }
      format.xml { render :xml => ret.to_xml(:root => "permissions")}
    end

  end

end
