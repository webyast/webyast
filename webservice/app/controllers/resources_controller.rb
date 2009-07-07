class ResourcesController < ApplicationController
  require "resource_registration"
  
  def index
    iface = params[:interface]
    if iface
      # return single resource if specific interface requested
      rsrc = ResourceRegistration.resources[iface]
      @resources = rsrc ? { iface => rsrc } : Hash.new
    else
      # return all known resources
      @resources = ResourceRegistration.resources
    end
    @node = "Yast"
  end
end
