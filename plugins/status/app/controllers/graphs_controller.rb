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

require 'metric'
require 'graph'
require 'uri'
require 'http_accept_language'

#
# Controller that exposes graph description in a RESTful
# way.
#
# GET /graphs returns all described graphs for the system status
#
# GET /graphs/id returns one graph description
#
class GraphsController < ApplicationController
  before_filter :login_required

  def init_translation
    init_gettext("webyast-status-ws", request.user_preferred_languages)
  end

  public

  # PUT /graphs
  def update
    permission_check("org.opensuse.yast.system.status.writelimits") # RORSCAN_ITL
    if params.has_key?(:graphs)
      @graph = Graph.new(params[:id], params[:graphs])
      @graph.save
    else
      logger.warn("No argument to update")
      raise InvalidParameters.new :graphs => "Missing"
    end
    render :show
  end

  # GET /graphs
  # GET /graphs.xml
  #
  def index
    permission_check("org.opensuse.yast.system.status.read") # RORSCAN_ITL
    init_translation

    bgr = params['background'] == 'true'
    Rails.logger.info "Reading status in background" if bgr

    @graph = Graph.find(:all, params[:checklimits] || true, {:background => bgr})
    render :show    
  end

  # GET /graphs/1
  # GET /graphs/1.xml
  #
  def show
    permission_check("org.opensuse.yast.system.status.read") # RORSCAN_ITL
    init_translation
    @graph = Graph.find(params[:id], params[:checklimits] || true)
  end
end
