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

  before_filter :check_read_permissions, :only => [:index, :show]

private
  
  def check_read_permissions
    authorize! :read, Repository
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
        render :index and return
      end
    end

    @show = params["show"]
    Rails.logger.debug "Displaying repository #{@show}" unless @show.blank?
    Rails.logger.debug "Available repositories: #{@repos.inspect}"
    respond_to do |format|
      format.html {}
      format.xml { render  :xml => @repos.to_xml( :root => "repositories", :dasherize => false ) }
      format.json { render :json => @repos.to_json( :root => "repositories", :dasherize => false ) }
    end
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
    respond_to do |format|
      format.xml { render  :xml => @repo.to_xml( :dasherize => false ) }
      format.json { render :json => @repo.to_json( :dasherize => false ) }
    end
  end

  def update
    authorize! :write, Repository
    param = params[:repository] || {}

    #id is either in params or in the struct (create method)
    @repo = Repository.new(params[:id] || param[:id] , param[:name], param[:enabled])

    raise InvalidParameters.new({:autorefresh => 'wrong'}) unless ["true","false"].include?(param[:autorefresh].to_s)
    raise InvalidParameters.new({:enabled => 'wrong'}) unless ["true","false"].include?(param[:enabled].to_s)
    raise InvalidParameters.new({:keep_packages => 'wrong'}) unless ["true","false"].include?(param[:keep_packages].to_s)

    param[:autorefresh] = param[:autorefresh].to_s == 'true'
    param[:enabled] = param[:enabled].to_s == 'true'
    param[:keep_packages] = param[:keep_packages].to_s == 'true'

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

  def new

    # load URLs of all existing repositories
    repos = Repository.find :all
    @repo = Repository.new
    @repo_urls = repos.map {|r| r.url}
    @repo_urls.reject! {|u| u.blank? }
  end


  # POST /repositories/
  def create
    update
  end

  def destroy
    authorize! :write, Repository

    begin
      repos = Repository.find(params[:id])
    rescue DBus::Error => exception
      unless request.format.html?
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return     
      end
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
