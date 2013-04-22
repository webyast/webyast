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

require 'shellwords'

class RepositoriesController < ApplicationController

  private

  def isint(str)
    str.match /\A[0-9]+\z/
  end

  public

  # GET /repositories.xml
  def index
    authorize! :read, Repository

    # read permissions were checked in a before filter
    begin
      @repos = Repository.find(:all)
    rescue DBus::Error => exception
      unless request.format.html?
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
      else
        flash[:error] = _("Cannot read repository list.")
        flash[:error] << (exception.dbus_message || exception.message)

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
    authorize! :read, Repository

    begin
      # RORSCAN_INL: User has already read permission for ALL repos
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
    rep_id = params[:id] || param[:id]

    # FIXME: is this needed??, Repository model already has some validation checks...
    raise InvalidParameters.new :id => "UNKNOWN" unless (rep_id && rep_id.is_a?(String))
    raise InvalidParameters.new :name => "UNKNOWN" unless (param[:name] && param[:name].is_a?(String))

    # Cannot be CWE-285 cause id does not depend on user authent.
    # RORSCAN_INL: Cannot be a mass_assignment cause they are strings only
    @repo = @create ? Repository.new(rep_id , param[:name], param[:enabled]) : Repository.find(rep_id).first

    if @repo.nil?
      if request.format.html?
        flash[:error] = _("Cannot update repository '%s', repository not found") % rep_id
        redirect_to :action => :index
      else
        render ErrorResult.error(404, 30, "Repository #{rep_id} not found")
      end

      return
    end

    raise InvalidParameters.new({:autorefresh => 'wrong'}) unless ["true","false"].include?(param[:autorefresh].to_s)
    raise InvalidParameters.new({:enabled => 'wrong'}) unless ["true","false"].include?(param[:enabled].to_s)
    raise InvalidParameters.new({:keep_packages => 'wrong'}) unless ["true","false"].include?(param[:keep_packages].to_s)

    param[:autorefresh] = param[:autorefresh].to_s == 'true'
    param[:enabled] = param[:enabled].to_s == 'true'
    param[:keep_packages] = param[:keep_packages].to_s == 'true'
    param[:priority] = param[:priority].to_i if isint(param[:priority].to_s)

    @repo.load param
    begin
      if @repo.save!
        flash[:message] = @create ? _("Repository '%s' has been created.") % @repo.name : _("Repository '%s' has been updated.") % @repo.name
      else
        if request.format.html?
          flash[:error] = @create ? _("Cannot create repository '%s': missing parameters.") % params[:id] :
              _("Cannot update repository '%s': missing parameters.") % params[:id]
        else
          render ErrorResult.error(404, 2, "packagekit error") and return
        end
      end
    rescue DBus::Error => exception
      if request.format.html?
        flash[:error] = @create ? _("Cannot create repository '%s': DBus error: %s") % [params[:id], exception.dbus_message.error_name] :
            _("Cannot update repository '%s': DBus error: %s") % [params[:id], exception.dbus_message.error_name]
      else
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
      end
    end

    respond_to do |format|
      format.html { redirect_to :action => :index }
      format.xml { render  :xml => @repo.to_xml( :dasherize => false ) }
      format.json { render :json => @repo.to_json( :dasherize => false ) }
    end
  end

  def new
    # load URLs of all existing repositories
    repos = Repository.find :all
    @repo = Repository.new
    @repo_urls = repos.map {|r| r.url}
    @repo_urls.reject! {|u| u.blank? }
  rescue DBus::Error => e
    if request.format.html?
      flash[:error] = _("Cannot create a new repository. %s.") % (e.dbus_message || e.message)
      redirect_to :action => :index
    else
      render ErrorResult.error(503, 2, "Cannot create a new repository. #{e.dbus_message || e.message}") and return
    end
  end


  # POST /repositories/
  def create
    @create = true
    update
  end

  def destroy
    authorize! :write, Repository

    begin
      # RORSCAN_INL: User has already read permission for ALL repos here
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
        flash[:error] = _("Repository '%s' was not found.") % params[:id]
        redirect_to :action => :index and return
      end
    end

    @repo = repos.first

    begin
      @repo.destroy

      # PackageKit doesn't return any status, check whether the repository is still present
      # RORSCAN_INL: User has already read/write permission for ALL repos here
      reps = Repository.find(params[:id])
      if reps.size > 0
        unless request.format.html?
          render ErrorResult.error(404, 2, "Cannot remove repository #{@repo.id}") and return
        else
          flash[:error] = _("Cannot remove repository '%s'") % params[:id]
        end
      end
    rescue DBus::Error => exception
      unless request.format.html?
        render ErrorResult.error(404, 20, "DBus Error: #{exception.dbus_message.error_name}") and return
      else
        flash[:error] = _("Cannot remove repository '%s'") % params[:id]
      end
    end

    respond_to do |format|
      format.html do
        flash[:message] = _("Repository '%s' has been deleted.") % @repo.name
        redirect_to :action => :index
      end
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

end
