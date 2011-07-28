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
  before_filter :check_read_permissions, :only => [:index, :show]
  layout 'main'

  # Initialize GetText and Content-Type.
  init_gettext 'webyast-software'

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
      unless request.format.html?
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
      else
        flash[:error] = _("Cannot read repository list.")
        @repos = []
        @permissions = {}
        render :index and return
      end
    end

    @write_permission = permission_check "org.opensuse.yast.system.repositories.write"
    @show = params["show"]
    Rails.logger.debug "Displaying repository #{@show}" unless @show.blank?
    Rails.logger.debug "Available repositories: #{@repos.inspect}"
  end

  # GET /repositories/my_repo.xml
  def show
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
    param = params[:repository] || {}

    @repo = Repository.new(param[:id], param[:name], param[:enabled])
    param[:autorefresh] = param[:autorefresh] == 'true'
    param[:enabled] = param[:enabled] == 'true'
    param[:keep_packages] = param[:keep_packages] == 'true'

    @repo.load param
    begin
      unless @repo.save!
        unless request.format.html?
          render ErrorResult.error(404, 2, "packagekit error") and return
        else
          flash[:error] = _("Cannot update repository '%s': missing parameters.") % "#{ERB::Util.html_escape params[:id]}"
          redirect_to :action => :index, :show => params[:id] and return          
        end
      end
    rescue DBus::Error => exception
      unless request.format.html?
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
      else
        flash[:error] = _("Cannot update repository '%s': missing parameters.") % "#{ERB::Util.html_escape params[:id]}"
        redirect_to :action => :index, :show => params[:id] and return          
      end
    end
    unless request.format.html?
      render :show
    else
      flash[:message] = _("Repository '%s' has been updated.") % "#{ERB::Util.html_escape @repo.name}"      
      redirect_to :action => :index, :show => params[:id] and return
    end
  end

  def add
    @repo = Repository.new
    @write_permission = permission_granted? "org.opensuse.yast.system.repositories.write" # RORSCAN_ITL

    # load URLs of all existing repositories
    repos = Repository.find :all
    @repo_urls = repos.map {|r| r.url}
    @repo_urls.reject! {|u| u.blank? }
  end


  # POST /repositories/
  def create
    update
  end

  def destroy
    permission_check "org.opensuse.yast.system.repositories.write" # RORSCAN_ITL

    begin
      repos = Repository.find(params[:id])
    rescue DBus::Error => exception
      unless request.format.html?
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return     end
    end

    if repos.nil? || repos.size.zero?
      Rails.logger.error "Repository #{params[:id]} was not found."
      unless request.format.html?
        render ErrorResult.error(404, 1, "Repository '#{params[:id]}' not found.") and return
      else
        flash[:error] = _("Repository '%s' was not found.") % "#{ERB::Util.html_escape params[:id]}"
        redirect_to :action => :index and return
      end
    end

    @repo = repos.first

    begin
      @repo.destroy

      # PackageKit doesn't return any status, check whether the repository is still present
      reps = Repository.find(params[:id])
      if reps.size > 0
        unless request.format.html?
          render ErrorResult.error(404, 2, "Cannot remove repository #{@repo.id}") and return
        else
          flash[:error] = _("Cannot remove repository '%s'") % "#{ERB::Util.html_escape params[:id]}"
        end
      end
    rescue DBus::Error => exception
      unless request.format.html?
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
      else
        flash[:error] = _("Cannot remove repository '%s'") % "#{ERB::Util.html_escape params[:id]}"
      end
    end

    unless request.format.html?
      render :show
    else
      flash[:message] = _("Repository '%s' has been deleted.") % "#{ERB::Util.html_escape @repo.name}"
      redirect_to :action => :index and return
    end
  end

end
