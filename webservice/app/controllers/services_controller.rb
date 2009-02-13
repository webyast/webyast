class ServicesController < ApplicationController
  before_filter :login_required

  private
  def init_services
    services = Hash.new
    Lsbservice.all.each do |d|
      begin
        service = Lsbservice.new d
        services[service.link] = service
      rescue # Don't fail on non-existing service. Should be more specific.
      end
    end
    session['services'] = services
  end
  def respond data
    if data
      respond_to do |format|
	format.xml do
	  render :xml => data.to_xml(:root => "services")
	end
	format.json do
	  render :json => data.to_json(:root => "services")
	end
	format.html do
	  render :xml => data.to_xml(:root => "services") #return xml only
	end
      end
    else
      render :nothing => true, :status => 404 unless @service # not found
    end
  end
  public

  def index
    init_services unless session['services']
    @services ||= session['services']
      #converting to an array for xml and json
      service_array = []
      @services.each {|key, value| 
        service_array << {:link => key, :path =>value.path, :commands => value.commands.join(","), 
                         :error_id => value.error_id, :error_string => value.error_string}
      }

      respond_to do |format|
	format.xml do
	  render :xml => service_array.to_xml(:root => "services")
        end
	format.json do
	  render :json => service_array.to_json(:root => "services")
	end
	format.html do
	  render :xml => service_array.to_xml(:root => "services") #return xml only
	end
      end
  end

  def show
    id = params[:id]
    init_services unless session['services']
    @service = session['services'][id]
    logger.debug "show@service #{@service.inspect}"
    respond @service
   end
end
