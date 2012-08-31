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

#
# Controller that exposes graph description in a RESTful
# way.
#
# GET /graphs returns all described graphs for the system status
#
# GET /graphs/id returns one graph description
#
class GraphsController < ApplicationController

public

  # PUT /graphs
  def update
    authorize! :writelimits, Metric
    if params.has_key?(:graphs)
      @graph = Graph.new(params[:id], params[:graphs])
      @graph.save
    else
      logger.warn("No argument to update")
      raise InvalidParameters.new :graphs => "Missing"
    end
    respond_to do |format|
      format.json { render :json => @graph.to_json }
      format.xml { render :xml => @graph.to_xml( :root => "graphs", :checklimits => false, :dasherize => false ) }
    end
  end

  # GET /graphs
  # GET /graphs.xml
  #
  def index
    authorize! :read, Metric
    @graph = Graph.find(:all, params[:checklimits] || true)
    respond_to do |format|
      format.html { redirect_to :controller => "status" }
      format.json { render :json => @graph.to_json }
      format.xml { render :xml => @graph.to_xml( :root => "graphs", :checklimits => params[:checklimits] || true, :dasherize => false ) }
    end
  end

  # GET /graphs/1
  # GET /graphs/1.xml
  #
  def show
    authorize! :read, Metric
    @graph = Graph.find(params[:id], params[:checklimits] || true)
    respond_to do |format|
      format.html { redirect_to :controller => "status" }
      format.json { render :json => @graph.to_json }
      format.xml { render :xml => @graph.to_xml( :root => "graphs", :checklimits => params[:checklimits] || true, :dasherize => false ) }
    end
  end
end
