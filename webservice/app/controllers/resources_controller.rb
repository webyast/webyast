class ResourcesController < ApplicationController
  require "resource_registration"
  
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
    @resource = Resource.find(params[:id].tr('-','.'))
    @node = "Yast"

    respond_to do |format|
      format.html
      format.xml { render :xml => @resource.to_xml }
      format.json{ render :json=> @resource.to_json}
    end
  end
end
