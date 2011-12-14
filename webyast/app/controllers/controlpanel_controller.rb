#--
# Webyast Webclient framework
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
# Control panel
#
# This is the default controller for webclient
#

require 'yaml'
require 'yast'

class ControlpanelController < ApplicationController
  before_filter :ensure_wizard, :only => [:nextstep, :backstep, :thisstep]

  respond_to :html

  layout "main"

  def index
    #return false if need_redirect
    @shortcuts = shortcuts_data
    @count = getNumberPermittedModules(@shortcuts)
  end

  def show_all
    @shortcut_groups = {}
    shortcuts_data.each do |name, data|
      data["groups"].each do |group|
        @shortcut_groups[group] ||= Array.new
        @shortcut_groups[group] << data
      end
    end
    @shortcut_groups.each do |group,val|
      val.sort! { |g1,g2| g1['title'] <=> g2['title'] }
    end
  end

  def getNumberPermittedModules(shortcuts)
    count = 0
    unless shortcuts.empty? 
      shortcuts.values.each do |data|
        if data['disabled'] != false
          count += 1
        end
      end
    end 
    return count
  end 
  
  def nextstep
    bs = Basesystem.new.load_from_session(session)
    unless params[:done].blank?
      #in case that user click multiple time on next button
      #redirect correct bnc#579470
      unless params[:done] == bs.current_step[:controller]
        redirect_to bs.current_step 
        return
      end
    end
    flash.keep #at first keep all flash because first call of flash load it from session and mark all flash messages as used
    flash.discard :notice #don't show success notice in basesystem (bnc#582803)
    redirect_to bs.next_step
  end

  def backstep
    redirect_to Basesystem.new.load_from_session(session).back_step
  end

  # when triggered by button/link from basesystem, shows current module from session
  def thisstep
    redirect_to Basesystem.new.load_from_session(session).current_step
  end

  protected

  # nextstep and backstep expect, that wizard session variables are set
  def ensure_wizard
    unless Basesystem.new.load_from_session(session).in_process?
       redirect_to "/controlpanel"
    end
  end

  # reads the shortcuts and returns the
  # hash with the data
  def shortcuts_data
    # save shortcuts in the Hash
    # each shortcuts file has each plugin shortcut named
    # by a key, we return the same key but namespaced with the plugin
    # name like pluginname:shortcutkey
    shortcuts = {}
    # read shortcuts from plugins
    #logger.debug Rails::Plugin::Loader.all_plugins.inspect
    #logger.debug Rails.configuration.load_paths
    permissions = Permission.find(:all, {:user_id => session[:user]})
    YaST::LOADED_PLUGINS.each do |plugin|
      logger.debug "looking into #{plugin.directory}"
      #Skip obsolete permissions module
      #unless plugin.name == "permissions"
      shortcuts.merge!(plugin_shortcuts(plugin, permissions))
      #end
    end
    #logger.debug shortcuts.inspect
    shortcuts
  end
  
  def translate_shortcuts(node)
    if node.is_a? Hash
      node.each do |key,data|
        node[key] = translate_shortcuts data
      end
    elsif node.is_a? Array
      counter = 0
      node.each do |data|
        node[counter] = translate_shortcuts data
        counter +=1
      end
    elsif node.is_a? String
      node = node.strip
      if node =~ /^_\(\"/ && node =~ /\"\)$/
        node = _(node[3..node.length-3]) #try to translate it
      end
    end
    return node
  end 

  # reads shortcuts of a specific plugin directory
  def plugin_shortcuts(plugin, all_permissions)
    permissions = {}
    all_permissions.each do |p|
      permissions[p[:id]] = p[:granted]
    end
    shortcuts = {}
    shortcuts_fn = File.join(plugin.directory, 'shortcuts.yml')
    if File.exists?(shortcuts_fn)
      #logger.debug "Shortcuts at #{plugin.directory}"
      shortcutsdata = YAML::load(File.open(shortcuts_fn))
      #loading translations 
      mo_files = Dir.glob(File.join(plugin.directory, "**", "*.mo"))
      if mo_files.size > 0
        locale_path = File.dirname(File.dirname(File.dirname(mo_files.first))) 
        #logger.info "Loading textdomain #{File.basename(mo_files.first, '.mo')} from #{locale_path} for shortcuts"
        opt = {:locale_path => locale_path}
        ActionController::Base.init_gettext(File.basename(mo_files.first, ".mo"), opt)
      else
        logger.warn "Cannot find shortcut translation for #{plugin.name}"
      end
      shortcutsdata = translate_shortcuts shortcutsdata
      return nil unless shortcutsdata.is_a? Hash
      # now go over each shortcut and add it to the modules
      shortcutsdata.each do |k,v|
        # use the plugin name and the shortcut key as
        # the new key
        shortcuts["#{plugin.name}:#{k}"] = v
        v["disabled"] = false #backward compatibility
        if v.include? "read_permissions"
          perms = v["read_permissions"]
          perms.each do |perm|
            v["disabled"] = v["disabled"] || !permissions[perm]
          end
        end
      end
    end
    shortcuts
  end
  

  # Checks if basic system module should be shown instead of control panel
  # and if it should, then also redirects to that module.
  # TODO check if controller from config exists
  def need_redirect
    first_run = !(Basesystem.new.load_from_session(session).initialized)
    logger.debug "first run of basesystem: #{first_run}.\n Session: #{session.inspect}."
    bs = Basesystem.find(session)
    # session variable is used to find out, if basic system module is needed
    return false if bs.completed?
    # error happen during basesystem, so show this page (prevent endless loop bnc#554989) 
    if first_run
      redirect_to bs.current_step
    else 
      logger.info "error occur during basesystem. render basesystem screen"
      render :action => "basesystem"
    end
    return true
  end
end
