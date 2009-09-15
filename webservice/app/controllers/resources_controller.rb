class ResourcesController < ApplicationController
  require "resource_registration"
  
  def index
    @resources = Resource.all
    @node = "Yast"

    logger.debug("Ahoj!")
    debugger
    respond_to do |format|
      format.html
      format.xml { render :xml => @resources.to_xml }
    end
  end

  def show
    @resources = Resource.find(params[:id])
    @node = "Yast"

    respond_to do |format|
      format.html
      format.xml { render :xml => @resources.to_xml }
    end
  end
end
