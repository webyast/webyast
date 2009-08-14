require 'yast_service'

class Service
  
  attr_accessor :name
  attr_accessor :status
  attr_accessor :execute

  def initialize    
  end
  
  # services = Service.find_all
  def self.find_all

    services	= []
    yapi_ret = YastService.Call("YaPI::SERVICES::Read")

    if yapi_ret.nil?
      raise "Can't get services list"
    else
      yapi_ret.each do |s|
	service		= Service.new
	service.name	= s["name"]
	service.status	= s["status"]
	Rails.logger.debug "service: #{service.inspect}"
	services << service
      end
    end
    services
  end

  # load the status of the service
  def self.find(id)
    yapi_ret = YastService.Call("YaPI::SERVICES::Get", id)

    raise "Got no data while loading service" if yapi_ret.empty?

    service		= Service.new
    service.name	= yapi_ret["name"]
    service.status	= yapi_ret["status"]

    Rails.logger.debug service.inspect
    service
  end


  def save
    ret = YastService.Call("YaPI::SERVICES::Execute", self.name, self.execute)

    Rails.logger.debug "Command returns: #{ret.inspect}"
    raise ret["stdout"] + ret["stderr"] if ret["exit"] != "0"
    true
  end
  
  
  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    
    xml.service do
      xml.tag!(:name, name )
      xml.tag!(:status, status, {:type => "integer"} )
      xml.tag!(:execute, execute )
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
