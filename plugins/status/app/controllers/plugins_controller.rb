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

include ApplicationHelper
require 'http_accept_language'
require 'plugin'

#
# Controller that exposes WebYaST service plugins in a RESTful
# way.
#
# GET /plugins returns status information of all WebYaST plugins
#
# GET /plugins/id returns status information of a plugin with the id "id"
#

class PluginsController < ApplicationController

protected

def load_translations
  resources = Resource.find :all
  resources.each {|resource|
    name = resource.href.split("/").last
    #searching directory for translation
    model_files = Dir.glob(File.join(RAILS_ROOT, "**", "#{name}_state.rb"))
    #trying plugin directory in the git 
    model_files = Dir.glob(File.join(RAILS_ROOT, "..","**", "#{name}_state.rb")) if model_files.empty? 
    unless model_files.empty?
      locale_path = File.join(File.dirname(File.dirname(File.dirname(model_files.first))),"locale")
      mo_files = Dir.glob(File.join(locale_path, "**", "*.mo"))
      unless mo_files.empty?
        domainname = File.basename(mo_files.first,".mo")
        opt = {:locale_path => locale_path}
        init_gettext(domainname, request.user_preferred_languages, opt)
      end
    end
  }
end

public
    
  # GET /plugins
  # GET /plugins.xml
  #
  def index
    permission_check("org.opensuse.yast.system.status.read")
    load_translations
    @plugins = Plugin.find(:all)
    render :show    
  end
  
  # GET /plugins/users
  # GET /plugins/users.xml
  #
  def show
    permission_check("org.opensuse.yast.system.status.read")
    load_translations
    @plugins = Plugin.find(params[:id])
    render :show    
  end

end
