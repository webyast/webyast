class ServicesController < ApplicationController
  before_filter :login_required

  private
  def init_services
    services = Hash.new
    Lsbservice.mock_each do |d| 
      begin
        service = Lsbservice.new d
        services[service.link] = service
      rescue Exception => e # Don't fail on non-existing service. Should be more specific.
        logger.debug e
      end
    end
    session['services'] = services
  end

  public

  def index
    unless permission_check( "org.opensuse.yast.system.services.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    init_services unless session['services']
    ser ||= session['services']
    #converting to an array for xml and json
    @services = []
    ser.each {|key, value| 
        command_array = []
        value.commands.each do |c|
           command_array << {:name=>c}
        end
        @services << {:link => key, :path =>value.path, :commands => command_array}
    }
  end

  def show
    unless permission_check( "org.opensuse.yast.system.services.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    id = params[:id]
    init_services unless session['services']
    @service = session['services'][id]
    logger.debug "show@service #{@service.inspect}"
  end
end
