require "scr"
require 'yast_service'
require 'yast/config_file'

class Service
  
  attr_accessor :name
  attr_accessor_with_default :status, 0

  def initialize(name)
    @name = name
  end
 
  # services = Service.find_all
  def self.find_all(params)

    services	= []
    if params.has_key?("custom")
      begin
        cfg = YaST::ConfigFile.new(:custom_services)
        cfg.each do |name, s|
	  service	= Service.new(name)
	  Rails.logger.debug "custom service: #{service.inspect}"
          services << service
        end
      rescue Exception => e
        Rails.logger.error e
      end
    else
      rl = `runlevel`.split(" ").last
      yapi_ret = YastService.Call("YaPI::SERVICES::Read", rl == "S" ? -1 : rl.to_i)

      if yapi_ret.nil?
        raise "Can't get services list"
      else
        yapi_ret.each do |s|
	  service	= Service.new(s)
	  # read status on demand, it takes much time
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
    Service.new(id)
  end


  # execute a service command (start, stop, ...)
  def save(cmd)

    begin
      cfg = YaST::ConfigFile.new(:custom_services)
      custom_service = cfg[self.name]
    rescue Exception => e
      Rails.logger.error "looking for service #{self.name}: #{e}"
      return { :stderr => e }
    end

    if custom_service.blank?
	Rails.logger.debug "no custom command found, calling YaPI..."
	ret = YastService.Call("YaPI::SERVICES::Execute", self.name, cmd)
    else
	command = custom_service[cmd]
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
      xml.name name
      xml.status status, {:type => "integer"}
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
