class ServicesController < ApplicationController
  require 'lsbservice'
  require 'service'
  def index
    @services = Array.new
    Lsbservice.all.each do |d|
      service = Service.new
      service.name = d
      @services << service
    end
    respond_to do |format|
      format.xml do
	render :xml => @services.to_xml
      end
      format.json do
	render :json => @services.to_json
      end
      format.html do
	render
      end
    end
  end
end
