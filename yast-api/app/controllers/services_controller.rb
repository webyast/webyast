class ServicesController < ApplicationController
  require 'service'
  def index
    @services = Array.new
    Dir.foreach( '/etc/init.d' ) do |d|
      next if d[0,1] == '.'
      next if d == "README"
      next if File.directory?( '/etc/init.d/'+d )
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
#        format.html do
#          render :html => @services.to_html
#        end
      end
  end
end
