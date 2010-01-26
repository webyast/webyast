class ResourcesController < ApplicationController
  require "resource_registration"
  caches_action :index
  
  def index
    @resources = Resource.all
    @node = "Yast"

    respond_to do |format|
      format.html
      format.xml { render :xml => @resources.to_xml }
      format.json{ render :json=> @resources.to_json}
    end
  end

  def do_respond
  end

  def show
    @resource = Resource.find(params[:id].tr('-','.')) #FIXME check if :id is passed
    unless @resource then
      render :file => "#{RAILS_ROOT}/public/404.html", :status => 404 and return 
    end
    @node = "Yast"
    respond_to do |format|
      format.html
      format.xml { render :xml => @resource.to_xml }
      format.json{ render :json=> @resource.to_json}
    end
  end
end
