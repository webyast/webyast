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

class PatchesController < ApplicationController

   before_filter :login_required

   # always check permissions
   before_filter :check_read_permissions, :only => [:index, :show]

  private

  def check_read_permissions
    permission_check "org.opensuse.yast.system.patches.read"  # RORSCAN_ITL
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

  def check_running_install
    running = 0
    jobs = Delayed::Job.find(:all)
    jobs.each { |job|
      running += 1 if job.handler.split("\n")[1].split[1].include?("patch:install:")
    } unless jobs.blank?
    Rails.logger.info("#{running} installation jobs in the queue")
    Rails.cache.delete("patch:installed") if running == 0 #remove installed patches from cache if the installation
                                                          #has been finished
    raise InstallInProgressException.new running if running > 0 #there is process which runs installation
  end

  def read_messages
    if File.exists?(Patch::MESSAGES_FILE)
      msg = File.read(Patch::MESSAGES_FILE)
      return [{:message => msg}]
    end

    return []
  end

  public

  # GET /patch_updates
  # GET /patch_updates.xml
  def index
    if params['messages']
      Rails.logger.debug "Reading patch messages"
      @msgs = read_messages

      respond_to do |format|
        format.xml { render  :xml => @msgs.to_xml( :root => "messages", :dasherize => false ) }
        format.json { render :json => @msgs.to_json( :root => "messages", :dasherize => false ) }
      end
      return
    end
    check_running_install
    # note: permission check was performed in :before_filter
    @patches = Patch.find(:all)
    @patches = @patches + collect_done_patches #report also which patches is installed
    respond_to do |format|
      format.xml { render  :xml => @patches.to_xml( :root => "patches", :dasherize => false ) }
      format.json { render :json => @patches.to_json( :root => "patches", :dasherize => false ) }
    end
  end

  # GET /patch_updates/1
  # GET /patch_updates/1.xml
  def show
    @patch_update = Patch.find(params[:id])
    if @patch_update.nil?
      logger.error "Patch: #{params[:id]} not found."
      render ErrorResult.error(404, 1, "Patch: #{params[:id]} not found.") and return
    end
  end

  # PUT /patch_updates/1
  # PUT /patch_updates/1.xml
  def update
    permission_check "org.opensuse.yast.system.patches.install" # RORSCAN_ITL
    @patch_update = Patch.find(params[:id])
    if @patch_update.blank?
      logger.error "Patch: #{params[:id]} not found."
      render ErrorResult.error(404, 1, "Patch: #{params[:id]} not found.") and return
    end
    unless @patch_update.install
      render ErrorResult.error(404, 2, "packagekit error") and return
    end
    render :show
  end

  # POST /patch_updates/
  def create
    permission_check "org.opensuse.yast.system.patches.install" # RORSCAN_ITL
    @patch_update = Patch.find(params[:patches][:resolvable_id].to_s)
    #Patch for Bug 560701 - [build 24.1] webYaST appears to crash after installing webclient patch
    #Packagekit returns empty string if the patch is allready installed.
    if @patch_update.is_a?(Array) && @patch_update.empty?
       logger.error "Patch is allready installed or not found #{@patch_update.inspect}"
       render ErrorResult.error(404, 1, "Patch is not required.") and return
    end

    if @patch_update.blank?
      logger.error "Patch: #{params[:patches][:resolvable_id]} not found."
      render ErrorResult.error(404, 1, "Patch: #{params[:patches][:resolvable_id]} not found.") and return
    end

    res = @patch_update.install(true) #always install in backend otherwise there is problem with long running updates
    render :show
  end


end
