require 'yast_service'

# = Service model
# Proviceds access to configured services.
# Uses YaPI for accessing standard system services (/etc/init.d)
# and vendor specific services (defined in config file).
class Service
  
  attr_accessor :name
  attr_accessor :status
  attr_accessor :description
  attr_accessor :summary

  def initialize(name)
    @name = name
    @description	= ""
    @summary		= ""
  end

  private

  # factored out because of testing
  def self.run_runlevel
    `/sbin/runlevel`
  end

  public

  # Return current system runlevel,
  def self.current_runlevel
    rl = run_runlevel.split(" ").last
    raise Exception.new('Non-number runlevel') if !/^[0-9]*$/.match rl and rl != "S"
    rl == "S" ? -1 : rl.to_i
  end
 
  # Read the list of all services.
  # If the key "custom" is present in the parameter hash, read the list of
  # custom services from the file. Otherwise, read LSB services available in
  # current system runlevel.
  #
  # If the key read_status is present in the parameter hash, read the status of
  # each service.
  #
  # services = Service.find_all
  def self.find_all(params)
    params = {} if params.nil?

    services	= []
    read_status	= params.has_key?("read_status") 

    rl = current_runlevel
    args	= {
	"runlevel"	=> [ "i", rl ],
	"read_status"	=> [ "b", read_status],
	"custom"	=> [ "b", params.has_key?("custom")],
	"shortdescription"	=> [ "b", true],
	"description"	=> [ "b", true]
    }
	
    yapi_ret = YastService.Call("YaPI::SERVICES::Read", args)

    if yapi_ret.nil?
        raise "Can't get services list"
    else
	yapi_ret.each do |s|
	  service	= Service.new(s["name"])
	  service.status= s["status"] if s.has_key?("status")
	  service.description	= s["description"] if s.has_key?("description")
	  service.summary	= s["shortdescription"] if s.has_key?("shortdescription")
#	  service.description	= s["shortdescription"] if s.has_key?("shortdescription") && !s["shortdescription"].empty?
	  Rails.logger.debug "service: #{service.inspect}"
	  services << service
        end
    end
    services
  end

  def self.find(id)
    # actually we do not need to read the real status now
    Service.new(id)
  end

  # load the status of the service
  def read_status(params)
    args	= {
	"service"	=> [ "s", self.name ],
	"custom"	=> [ "b", params.has_key?("custom")],
    }
    yapi_ret = YastService.Call("YaPI::SERVICES::Read", args)

    Rails.logger.debug "Command returns: #{yapi_ret.inspect}"

    if yapi_ret.nil?
        raise "Can't get service status"
    else
	@status	= yapi_ret.first["status"] if !yapi_ret.empty? && yapi_ret.first.has_key?("status")
    end
  end

  # execute a service command (start, stop, ...)
  def save(params)

    args	= {
	"name"		=> [ "s", self.name ],
	"action"	=> [ "s", params["execute"] ],
	"custom"	=> [ "b", params.has_key?("custom") ]
    }
    ret = YastService.Call("YaPI::SERVICES::Execute", args)

    Rails.logger.debug "Command returns: #{ret.inspect}"
    ret.symbolize_keys!
  end

  
  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    
    xml.service do
      xml.name name
      xml.description description
      xml.summary summary
      xml.status status, {:type => "integer"}
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
