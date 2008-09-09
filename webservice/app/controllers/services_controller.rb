class ServicesController < ApplicationController
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
    STDERR.puts "Respond #{data.class}"
    if data
      respond_to do |format|
	format.xml do
	  render :xml => data.to_xml
	end
	format.json do
	  render :json => data.to_json
	end
	format.html do
	  render
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
    respond @services
  end

  def show
    id = params[:id]
    init_services unless session['services']
    @service = session['services'][id]
    STDERR.puts "show@service #{@service}"
    respond @service
   end
end
