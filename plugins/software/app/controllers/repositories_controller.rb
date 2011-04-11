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

class RepositoriesController < ApplicationController

  before_filter :login_required
  before_filter :check_read_permissions, :only => [:index]

  private

  def check_read_permissions
    permission_check "org.opensuse.yast.system.repositories.read" # RORSCAN_ITL
  end


  public

  # GET /repositories.xml
  def index
    # read permissions were checked in a before filter
    begin
      @repos = Repository.find(:all)
    rescue DBus::Error => exception
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
    end

  end

  # GET /repositories/my_repo.xml
  def show
    permission_check "org.opensuse.yast.system.repositories.read" # RORSCAN_ITL

    # read permissions were checked in a before filter
    begin
      repos = Repository.find(params[:id])
    rescue DBus::Error => exception
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
    end

    if repos.nil? || repos.size.zero?
      Rails.logger.error "Repository #{params[:id]} not found."
      render ErrorResult.error(404, 1, "Repository #{params[:id]} was not found.") and return
    end

    @repo = repos.first
  end

  def update
    permission_check "org.opensuse.yast.system.repositories.write" # RORSCAN_ITL

    param = params[:repositories] || {}

    @repo = Repository.new(params[:id], param[:name], param[:enabled])
    @repo.load param

    begin
      unless @repo.save!
        render ErrorResult.error(404, 2, "packagekit error") and return
      end
    rescue DBus::Error => exception
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
    end

    render :show
  end

  # POST /repositories/
  def create
    permission_check "org.opensuse.yast.system.repositories.write" # RORSCAN_ITL

    param = params[:repositories] || {}

    @repo = Repository.new(params[:id].to_s, param[:name].to_s, param[:enabled])
    @repo.load param

    begin
      unless @repo.save!
        render ErrorResult.error(404, 2, "Cannot save repository '#{@repo.id}'") and return
      end
    rescue DBus::Error => exception
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
    end

    render :show
  end

  def destroy
    permission_check "org.opensuse.yast.system.repositories.write" # RORSCAN_ITL

    begin
      repos = Repository.find(params[:id])
    rescue DBus::Error => exception
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
    end

    if repos.nil? || repos.size.zero?
      Rails.logger.error "Repository #{params[:id]} was not found."
      render ErrorResult.error(404, 1, "Repository '#{params[:id]}' not found.") and return
    end

    @repo = repos.first

    begin
      @repo.destroy

      # PackageKit doesn't return any status, check whether the repository is still present
      reps = Repository.find(params[:id])
      if reps.size > 0
        render ErrorResult.error(404, 2, "Cannot remove repository #{@repo.id}") and return
      end
    rescue DBus::Error => exception
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
    end

    render :show
  end

end
