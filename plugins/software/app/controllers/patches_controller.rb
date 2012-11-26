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

class PatchesController < ApplicationController
  include ERB::Util

  before_filter :cache_check, :only => [:index, :show_summary]
  after_filter :drop_cache

  # include locale in the cache path to cache different translations
  caches_action :show_summary, :expires_in => Patch::EXPIRATION_TIME, :cache_path => Proc.new {"webyast_patch_summary_#{FastGettext.locale}"}
  caches_action :index, :expires_in => Patch::EXPIRATION_TIME, :cache_path => Proc.new {"webyast_patch_index_#{FastGettext.locale}"}

private

  # check permission and validate cache content
  def cache_check
    authorize! :read, Patch

    cached_mtime = Rails.cache.fetch("webyast_patch_mtime")
    current_mtime = Patch.mtime

    if current_mtime != cached_mtime
      Rails.logger.info "Expiring patch cache: cached: #{cached_mtime}, modified: #{current_mtime}"
      # update the time stamp
      Rails.cache.write("webyast_patch_mtime", current_mtime)
      expire_patch_cache
    end
  end

  # drop the cached results (needed in some cases, e.g. an error occured, SW management locked)
  # to force retry again instead of returning the cached error
  def drop_cache
    if @drop_cache
      Rails.logger.info "Dropping the cache, do full reload next time"
      expire_patch_cache
    end
  end

  def expire_patch_cache
    # expire all translations
    expire_fragment(/webyast_patch_summary_/)
    expire_fragment(/webyast_patch_index_/)
  end

  def collect_done_patches
    return Rails.cache.fetch("patch:installed") || []
  end

  def read_messages
    if File.exists?(Patch::MESSAGES_FILE)
      msg = File.read(Patch::MESSAGES_FILE)
      return [{:message => msg}]
    end

    return []
  end

  def refresh_timeout
    # the default is 1 hours
    timeout = ControlPanelConfig.read 'patch_status_timeout', 1.hour

    if timeout.zero?
      Rails.logger.info "Patch status autorefresh is disabled"
    else
      Rails.logger.info "Autorefresh patch status after #{timeout} seconds"
    end

    return timeout
  end

  # remove the last cached result
  def reset_results
    Rails.logger.info "Clearing patch result cache"
    Rails.cache.delete("patch:installed")
    Rails.cache.delete("patch:failed")
  end

  public

  # GET /patches
  # GET /patches.xml
  def index
    authorize! :read, Patch
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
      # FIXME: do NOT put messages to flash, the storage is VERY limited (< 4kB), just put a link to show them
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
    running, remaining = Patch.installing
    if running #there is process which runs installation
      raise InstallInProgressException.new( running )unless request.format.html?
      # patch update installation in progress
      # display the message and reload after a while
      @flash_message = h _("Cannot read available patches, patch installation is in progress.")

      if remaining.present?
        @flash_message << "<br/>".html_safe
        @flash_message << h(n_("There is one patch to install.", "There are %d patches to install.", remaining) % remaining)
      end

      @patch_updates = []
      @error = true
      @reload = true
    else
      #no installation process
      begin
        @patch_updates = Patch.find(:all)
      rescue Exception => e
        if e.description.match /Repository (.*) needs to be signed/
          flash[:error] = ((h _("Cannot read patch updates: GPG key for repository %s is not trusted.")) % "<em>#{h $1}</em>").html_safe
        elsif e.description.match /System management is locked by the application with pid ([0-9]+) \((.*)\)\./
          flash[:warning] = _("Software management is locked by another application ('%s', PID %s).") % [$2, $1]
          @drop_cache = true
        else
          flash[:error] = e.message
          @drop_cache = true
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
    authorize! :read, Patch
    # RORSCAN_INL: User has already read permission for ALL patch info
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
    # permission check is done in before_filter

    error = nil
    patch_updates = nil
    ref_timeout = nil
    error_type = :none
    running, remaining = Patch.installing

    if running
      ref_timeout = 10.seconds
      error_type = :install
      error_string = h _("Patch installation is in progress.")

      if remaining.present?
        error_string << "<br/>".html_safe
        error_string << h(n_("There is one patch to install.", "There are %d patches to install.", remaining) % remaining)
      end
    elsif PatchesState.read[:message_id] == "PATCH_EULA" #checking if there is a missing licence
      error_type = :license
    else
      #evaluate available patches
      begin
        patch_updates = Patch.find :all
        patch_updates = patch_updates + collect_done_patches #report also which patches is installed
        ref_timeout = refresh_timeout
      rescue Exception => error
        if error.description.match /Repository (.*) needs to be signed/
          error_string = (_("Cannot read patch updates: GPG key for repository <em>%s</em> is not trusted.") % $1).html_safe
          error_type = :unsigned
        elsif error.description.match /System management is locked by the application with pid ([0-9]+) \((.*)\)\./
          error_string = _("Software management is locked by another application ('%s', PID %s).") % [$2, $1]
          error_type = :locked
          @drop_cache = true
        else
          error_string = error.message
          error_type = :unknown
          @drop_cache = true
        end
      end
    end

    patches_summary = nil
    Rails.logger.debug "patch_updates: #{patch_updates.inspect}"
    Rails.logger.debug "installed patches: #{Rails.cache.fetch("patch:installed"){[]}.inspect}"
    Rails.logger.debug "failed patches: #{Rails.cache.fetch("patch:failed"){[]}.inspect}"

    if patch_updates
      patches_summary = { :security => 0, :important => 0, :optional => 0}
      [:security, :important, :optional].each do |patch_type|
        patches_summary[patch_type] = patch_updates.find_all { |p| p.kind == patch_type.to_s && !p.installed }.size
      end
      # add 'low' patches to optional
      patches_summary[:optional] += patch_updates.find_all { |p| p.kind == 'low' && !p.installed }.size
      # add 'normal' patches to important
      patches_summary[:important] += patch_updates.find_all { |p| p.kind == 'normal' && !p.installed }.size
    else
      flash.clear #no flash from load_proxy
    end

    Rails.logger.debug "Patch summary: #{{:patch => patches_summary, :error => error,
     :error_string => error_string, :error_type => error_type, :refresh_timeout => ref_timeout}.inspect}"

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
    authorize! :read, Patch
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

    Patch::BM.background_enabled? ? Patch.install_all_background : Patch.install_all

    # force refreshing of the cache
    expire_patch_cache

    show_summary
  end

  # POST /patches/install
  # Installing one or more patches which has given via param

  def install
    authorize! :install, Patch

    running, remaining = Patch.installing

    if running
      if request.format.html?
        error_string = _("Patch installation is in progress.")

        if remaining.present?
          error_string << " "
          error_string << n_("There is one patch to install.", "There are %d patches to install.", remaining) % remaining
        end

        flash[:error] = error_string
      end

      render :show and return
    end

    update_array = []

    #search for patches and collect the ids
    params.each { |key, value|
      if key.start_with?("patch_") || key == "id"
        update_array << value
      end
    }
    @patch_update = Patch.new({})

    # remove the last cached results
    reset_results

    begin
      if !update_array.empty?
        Patch::BM.background_enabled? ? Patch.install_patches_by_id_background(update_array) : Patch.install_patches_by_id(update_array)

        # force refreshing of the cache
        expire_patch_cache
      end
    # FIXME: this might hide some errors
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

  def message
    authorize! :read, Patch
    authorize! :install, Patch

    logger.warn "Confirmation of reading patch messages"
    File.delete Patch::MESSAGES_FILE

    respond_to do |format|
      format.html {
        redirect_to "/"
      }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

  def license
    authorize! :read, Patch
    authorize! :install, Patch

    if params[:accept].present? || params[:reject].present?
      params[:accept].present? ? Patch.accept_license : Patch.reject_license

      Patch.clear_cache

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
          @text = @text.html_safe
        else
          (h @text).gsub!(/^\n\n$/, '<p class="eula_paragraph">').html_safe
        end
        render
      }
      format.xml { render  :xml => Patch.license.to_xml( :root => "licenses", :dasherize => false ) }
      format.json { render :json => Patch.license.to_json( :root => "licenses", :dasherize => false ) }
    end
  end


end
