require 'yast/config_file'
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
  attr_accessor :custom
  attr_accessor :enabled
  attr_accessor :required_for_start
  attr_accessor :required_for_stop

  FILTER_FILE	= "filter_services.yml"

  def initialize(name)
    @name = name
    @description	= ""
    @summary		= ""
    @custom		= false
    @enabled		= true
    @required_for_start	= []
    @required_for_stop	= []
  end

  private

  # factored out because of testing
  def self.run_runlevel
    `/sbin/runlevel`
  end

  public

  # reading configuration file
  #
  def self.parse_filter(path = nil)
    path = File.join(Paths::CONFIG,FILTER_FILE) if path == nil

    #reading configuration file
    if File.exists?(path)
	file = YaST::ConfigFile.new(path)
	return file["services"] || []
    end
    return []
  end

  # Return current system runlevel,
  def self.current_runlevel
    rl = run_runlevel.split(" ").last
    raise Exception.new('Non-number runlevel') if !/^[0-9]*$/.match rl and rl != "S"
    rl == "S" ? -1 : rl.to_i
  end
 
  # Read the list of all services.
  #
  # If the key read_status is present in the parameter hash, read the status of
  # each service.
  #
  # services = Service.find_all
  def self.find_all(params)
    params = {} if params.nil?

    services	= []
    services_map= {} # helper structure

    filter		= parse_filter

    rl = current_runlevel
    args	= {
	"runlevel"	=> [ "i", rl ],
	"read_status"	=> [ "b", params.has_key?("read_status")],
	"shortdescription"	=> [ "b", true],
	"description"	=> [ "b", true],
	"dependencies"	=> [ "b", true],
	"filter"	=> [ "as", filter ]
    }
	
    # read list of all init.d services
    yapi_ret = YastService.Call("YaPI::SERVICES::Read", args)

    if yapi_ret.nil?
        raise "Can't get services list"
    else
	yapi_ret.each do |s|
	  service	= Service.new(s["name"])
	  service.status	= s["status"] if s.has_key?("status")
	  service.description	= s["description"] if s.has_key?("description")
	  service.summary	= s["shortdescription"] if s.has_key?("shortdescription")
	  service.enabled	= s["enabled"] if s.has_key?("enabled")
	  service.required_for_start		= s["required_for_start"] if s.has_key?("required_for_start")
	  service.required_for_stop		= s["required_for_stop"] if s.has_key?("required_for_stop")
	  Rails.logger.debug "service: #{service.inspect}"
	  services_map[s["name"]]	= service
        end
    end

    # read list of custom (user defined) services
    args["custom"]	= [ "b", true]
    args["dependencies"]= [ "b", false]
	
    yapi_ret = YastService.Call("YaPI::SERVICES::Read", args)

    if yapi_ret.nil?
        raise "Can't get custom services list"
    else
	yapi_ret.each do |s|
	  service	= Service.new(s["name"])
	  service.status	= s["status"] if s.has_key?("status")
	  service.description	= s["description"] if s.has_key?("description")
	  service.summary	= s["shortdescription"] if s.has_key?("shortdescription")
	  service.custom	= true
	  # service.enabled cannot be checked, we do not know how for custom service
	  Rails.logger.debug "service: #{service.inspect}"
	  services_map[s["name"]]	= service
        end
    end
    if filter.nil? || filter.empty?
	services	= services_map.values.sort { |a,b|  a.name <=> b.name }
    else
	filter.each do |name|
	    services << services_map[name] if services_map.has_key? name
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
	"custom"	=> [ "b", params["custom"] == "true"],
    }
    yapi_ret = YastService.Call("YaPI::SERVICES::Read", args)

    Rails.logger.debug "Command returns: #{yapi_ret.inspect}"

    if yapi_ret.nil?
        raise "Can't get service status"
    else
	@status	= yapi_ret.first["status"] if !yapi_ret.empty? && yapi_ret.first.has_key?("status")
	@enabled= yapi_ret.first["enabled"] if !yapi_ret.empty? && yapi_ret.first.has_key?("enabled")
	@custom	= params["custom"] == "true"
    end
  end

  # execute a service command (start, stop, ...)
  def save(params)
    args	= {
	"name"		=> [ "s", self.name ],
	"action"	=> [ "s", params["execute"] ],
	"custom"	=> [ "b", params["custom"] == "true" ]
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
      xml.custom custom
      xml.enabled enabled
      xml.status status, {:type => "integer"}
      xml.required_for_start({:type => "array"}) do
	required_for_start.each do |s|
	    xml.service s
	end
      end
      xml.required_for_stop({:type => "array"}) do
	required_for_stop.each do |s|
	    xml.service s
	end
      end
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
