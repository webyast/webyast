require "scr"
require 'yast_service'
require 'yast/config_file'

class Service
  
  attr_accessor :name
  attr_accessor_with_default :status, 0

  def initialize    
  end

 
  # services = Service.find_all
  def self.find_all(params)

    services	= []
    if params.has_key?("custom")
      begin
        cfg = YaST::ConfigFile.new(:custom_services)
        cfg.each do |name, s|
	  service	= Service.new
	  service.name	= name
	  # TODO read the service status?
	  Rails.logger.debug "custom service: #{service.inspect}"
          services << service
        end
      rescue Exception => e
        Rails.logger.error e
      end
    else
      yapi_ret = YastService.Call("YaPI::SERVICES::Read")

      if yapi_ret.nil?
        raise "Can't get services list"
      else
        yapi_ret.each do |s|
	  service	= Service.new
	  service.name	= s["name"]
#	  service.status= s["status"] read on demand, this takes much time
	  Rails.logger.debug "service: #{service.inspect}"
	  services << service
        end
      end
    end
    services
  end

  # load the status of the service
  def self.find(id)

    # actually we do not need to read the real status now
    service		= Service.new
    service.name	= id
    service
  end


  # execute a service command (start, stop, ...)
  def save(cmd)

    custom_service	= {}
    begin
      cfg = YaST::ConfigFile.new(:custom_services)
      custom_service	= cfg[self.name] if cfg.has_key?(self.name)
    rescue Exception => e
      Rails.logger.error "looking for service #{self.name}: #{e}"
      return { :stderr => e }
    end

    command = ""
    command = custom_service[cmd] unless custom_service.nil?

    if command.nil? or command.empty?
	Rails.logger.debug "no custom command found, calling YaPI..."
	ret = YastService.Call("YaPI::SERVICES::Execute", self.name, cmd)
    else
	Rails.logger.debug "Service commmand #{command}"
	ret = Scr.instance.execute([command])
    end

    Rails.logger.debug "Command returns: #{ret.inspect}"
    ret
  end

  
  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    
    xml.service do
      xml.tag!(:name, name )
      xml.tag!(:status, status, {:type => "integer"} )
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
