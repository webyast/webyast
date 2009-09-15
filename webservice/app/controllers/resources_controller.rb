class ResourcesController < ApplicationController
  require "resource_registration"
  
  def index
    @resources = Resource.all
    do_respond
  end

  def do_respond
    @node = "Yast"

    respond_to do |format|
      format.html
      format.xml { render :xml => @resources.to_xml }
      format.json{ render :json=> @resources.to_json}
    end
  end

  def show
    @resources = Resource.find(params[:id])
    do_respond
  end
end
