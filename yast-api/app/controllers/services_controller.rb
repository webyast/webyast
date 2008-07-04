class ServicesController < ApplicationController
  require 'lsbservice'
  private
  def init_services
    services = Hash.new
    Lsbservice.all.each do |d|
      service = Lsbservice.new d
      services[service.name] = service
    end
    session['services'] = services
  end
  def respond data
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
  end
  public
  def index
    init_services unless session['services']
    @services ||= session['services']
    respond @services
  end
  def show
    id = params[:id]
#    STDERR.puts "services/show #{id}"
    init_services unless session['services']
    @service = session['services'][id]
#    STDERR.puts "@service #{@service}"
    if @service.nil?
#      STDERR.puts "NIL"
      render :nothing => true, :status => 404 unless @service # not found
      return
    end
    respond @service
  end
end
