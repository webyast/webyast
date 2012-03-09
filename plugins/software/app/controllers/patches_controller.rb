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

require 'singleton'
require 'plugin_job'
require 'base'

class PatchesController < ApplicationController

  # always check permissions
  before_filter :check_read_permissions, :only => [:index, :show, :show_summary, :load_filter, :license]

private

  def check_read_permissions
    authorize! :read, Patch
  end

  def collect_done_patches
    done = []
    installed = Rails.cache.fetch("patch:installed") || []
    installed.each { |patch_id|
      # e.g.: 'suse-build-key;1.0-907.30;noarch;@System'
      attrs = patch_id.split(';')
      done << Patch.new(:resolvable_id => attrs[1],
                        :name => attrs[0],
                        :arch => attrs[2],
                        :repo => attrs[3],
                        :installed => true)
    }
    return done
  end

  def read_messages
    if File.exists?(Patch::MESSAGES_FILE)
      msg = File.read(Patch::MESSAGES_FILE)
      return [{:message => msg}]
    end

    return []
  end

  def refresh_timeout
    # the default is 24 hours
    timeout = ControlPanelConfig.read 'patch_status_timeout', 24*60*60

    if timeout.zero?
      Rails.logger.info "Patch status autorefresh is disabled"
    else
      Rails.logger.info "Autorefresh patch status after #{timeout} seconds"
    end

    return timeout
  end

  def running_install_jobs
    running = PluginJob.running(:Patch, :install)
    Rails.logger.info("#{running} installation jobs in the queue")
    Rails.cache.delete("patch:installed") if running == 0 #remove installed patches from cache if the installation
                                                          #has been finished
    running
  end

  public

  # GET /patches
  # GET /patches.xml
  def index
    @msgs = read_messages
    if params['messages']
      Rails.logger.debug "Reading patch messages"
      respond_to do |format|
        format.xml { render  :xml => @msgs.to_xml( :root => "messages", :dasherize => false ) }
        format.json { render :json => @msgs.to_json( :root => "messages", :dasherize => false ) }
      end
      return
    end

    if !@msgs.blank? && request.format.html?
      #@msgs.gsub!('<br/>', ' ')
      @message = @msgs.map{|s| s[:message]}.to_s.gsub(/\n/, '')
      flash[:warning] = _("There are patch installation messages available") + details(@message)
    end

    #checking if a license is requiredrequired
    if PatchesState.read[:message_id] == "PATCH_EULA"
      if request.format.html?
        redirect_to :action => "license" #move to page for license confirmation
      else
        raise LicenseRequiredException.new
      end
    end

    #checking if an installation is running
    running = running_install_jobs
    if running > 0 #there is process which runs installation
      raise InstallInProgressException.new( running )unless request.format.html?
      # patch update installation in progress
      # display the message and reload after a while
      @flash_message = _("Cannot obtain patches, installation in progress. Remain %d packages.") % running
      @patch_updates = []
      @error = true
      @reload = true      
    else
      #no installation process
      begin
        @patch_updates = Patch.find(:all)
      rescue Exception => e
        if e.description.match /Repository (.*) needs to be signed/
          flash[:error] = _("Cannot read patch updates: GPG key for repository <em>%s</em> is not trusted.") % $1
        else
          flash[:error] = e.message
        end
        @patch_updates = []
        @error = true
      end
      @patch_updates = @patch_updates + collect_done_patches #report also which patches is installed
    end
    logger.info "All patches: #{@patch_updates.inspect}"
    respond_to do |format|
      format.html {}
      format.xml { render  :xml => @patch_updates.to_xml( :root => "patches", :dasherize => false ) }
      format.json { render :json => @patch_updates.to_json( :root => "patches", :dasherize => false ) }
    end
  end

  # GET /patches/1
  # GET /patches/1.xml
  def show
    @patch_update = Patch.find(params[:id])
    if @patch_update.nil?
      logger.error "Patch: #{params[:id]} not found."
      render ErrorResult.error(404, 1, "Patch: #{params[:id]} not found.") and return
    end
    respond_to do |format|
      format.xml { render  :xml => @patch_update.to_xml( :root => "patches", :dasherize => false ) }
      format.json { render :json => @patch_update.to_json( :root => "patches", :dasherize => false ) }
    end
  end

  # this action is rendered as a partial, so it can't throw
  def show_summary
    error = nil
    patch_updates = nil
    refresh = false
    error_type = :none
    running = running_install_jobs
    if running > 0 #there is process which runs installation
      refresh = true if running > 0 #refresh state of installation
      error_string = _("Cannot obtain patches, installation in progress. Remain %d patches.") % running
      error_type = :install
    elsif PatchesState.read[:message_id] == "PATCH_EULA" #checking if there is a missing licence
      error_type = :license
    else
      #evaluate available patches
      begin
        patch_updates = Patch.find :all
        patch_updates = patch_updates + collect_done_patches #report also which patches is installed
        refresh = true
      rescue Exception => error
        if error.description.match /Repository (.*) needs to be signed/
          error_string = _("Cannot read patch updates: GPG key for repository <em>%s</em> is not trusted.") % $1
          error_type = :unsigned
        else
          error_string = error.message
          error_type = :unknown
        end
      end
    end

    patches_summary = nil

    if patch_updates
      patches_summary = { :security => 0, :important => 0, :optional => 0}
      [:security, :important, :optional].each do |patch_type|
        patches_summary[patch_type] = patch_updates.find_all { |p| p.kind == patch_type.to_s }.size
      end
      # add 'low' patches to optional
      patches_summary[:optional] += patch_updates.find_all { |p| p.kind == 'low' }.size
    else
      erase_redirect_results #reset all redirects
      erase_render_results
      flash.clear #no flash from load_proxy
    end

    # don't refresh if there was an error
    ref_timeout = refresh ? refresh_timeout : nil
    respond_to do |format|
      format.html { render :partial => "patch_summary", 
                           :locals => { :patch => patches_summary, 
                           :error => error, 
                           :error_string => error_string, 
                           :error_type => error_type,
                           :refresh_timeout => ref_timeout } }
      format.json  { render :json => patches_summary }
    end
  end

  def load_filtered
    @patch_updates = Patch.find :all
    kind = params[:value]
    search_map = { "green" => ["normal","low"], "security" => ["security"],
                   "important" => "important", 'optional' => ["enhancement"] }
    unless kind == "all"
      search_list = search_map[kind] || [kind]
      @patch_updates = @patch_updates.find_all { |patch| search_list.include?(patch.kind) }
    end
    render :partial => "patches"
  end


  # POST /patches/start_install_all
  # Starting installation of all proposed patches
  def start_install_all
    authorize! :install, Patch
    logger.info "Start installation of all patches"
    Patch.install_patches Patch.find(:all)
    show_summary
  end

  # POST /patches/install
  # Installing one or more patches which has given via param

  def install
    authorize! :install, Patch
    update_array = []

    #search for patches and collect the ids
    params.each { |key, value|
      if key =~ /\D*_\d/ || key == "id"
        update_array << value
      end
    }
    @patch_update = Patch.new({})
    begin
      Patch.install_patches_by_id update_array
    rescue Exception => e
      Rails.logger.info "Some patches are not needed in #{update_array.inspect} anymore: #{e.message}"
    end

    logger.debug "*** Check before redirect: basesystem setup completed -> #{Basesystem.new.load_from_session(session).completed?}"
    if request.format.html?
      if Basesystem.new.load_from_session(session).completed?
        redirect_to :controller => "controlpanel", :action => "index" and return
      else
        redirect_to :controller => "controlpanel", :action => "nextstep" and return
      end
    end
    render :show
  end

  def license
    authorize! :install, Patch
    if params[:accept].present? || params[:reject].present?
      params[:accept].present? ? Patch.accept_license : Patch.reject_license
      YastCache.delete(Plugin.new(),"patch")
      if request.format.html?
        redirect_to "/"
      else
        @patch_update = Patch.new({})
        render :show
      end
      return
    end

    respond_to do |format|
      format.html {
        @license = Patch.license.first
        @text = @license[:text] if @license
        if @text =~ /DT:Rich/ #text is richtext for packager
          #rid of html tags
          @text.gsub!(/&lt;.*&gt;/,'')
          # unescape all ampersands
          @text.gsub!(/&amp;([a-zA-Z0-9]+;)/,"&\\1")
        end
        render
      }
      format.xml { render  :xml => Patch.license.to_xml( :root => "licenses", :dasherize => false ) }
      format.json { render :json => Patch.license.to_json( :root => "licenses", :dasherize => false ) }
    end
  end


end
