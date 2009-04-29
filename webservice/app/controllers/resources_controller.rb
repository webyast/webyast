class ResourcesController < ApplicationController
  require "lib/resource_registration"
  
  def index
    if params[:interface]
      @resources = Hash.new
      @resources[params[:interface]] = ResourceRegistration.resources[params[:interface]]
    else
      @resources = ResourceRegistration.resources
    end
    @node = "Yast"
    # respond_to do |format|
    #  format.html { ... }
    #  format.xml { ... }
    # end
    #
    # -> index.erb.<format>
  end
end
