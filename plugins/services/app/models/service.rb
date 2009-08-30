require "scr"
require 'yast_service'
require 'yast/config_file'

class Service
  
  attr_accessor :name
  attr_accessor :status

  def initialize(name)
    @name = name
  end

  private

  # factored out because of testing
  def self.run_runlevel
    `runlevel`
  end

  public

  def self.current_runlevel
    rl = run_runlevel.split(" ").last
    raise Exception.new('Non-number runlevel') if !/^[0-9]*$/.match rl and rl != "S"
    rl == "S" ? -1 : rl.to_i
  end
 
  # services = Service.find_all
  def self.find_all(params)
    params = {} if params.nil?

    services	= []
    read_status	= params.has_key?("read_status") 

    if params.has_key?("custom")
      begin
        cfg = YaST::ConfigFile.new(:custom_services)
        cfg.each do |name, s|
	  service	= Service.new(name)
	  if read_status and s.has_key?("status")
	    ret = Scr.instance.execute([s["status"]])
	    service.status = ret[:exit]
	  end
	  Rails.logger.debug "custom service: #{service.inspect}"
          services << service
        end
      rescue Exception => e
        Rails.logger.error e
      end
    else
      rl = current_runlevel
      params	= {
	  "runlevel"	=> [ "i", rl ],
	  "read_status"	=> [ "b", read_status]
      }
      yapi_ret = YastService.Call("YaPI::SERVICES::Read", params)

      if yapi_ret.nil?
        raise "Can't get services list"
      else
        yapi_ret.each do |s|
	  service	= Service.new(s["name"])
	  service.status= s["status"] if s.has_key?("status")
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

  def read_status
    @status = save('status')['exit']
  end

  # execute a service command (start, stop, ...)
  def save(cmd)

    begin
      cfg = YaST::ConfigFile.new(:custom_services)
      custom_service = cfg[self.name]
    rescue YaST::ConfigFile::NotFoundError
      Rails.logger.debug "No custom service defined"
      custom_service = nil
    rescue Exception => e
      Rails.logger.error "looking for service #{self.name}: #{e}"
      return { :stderr => e }
    end

    if custom_service.blank?
	Rails.logger.debug "no custom command found, calling YaPI..."
	ret = YastService.Call("YaPI::SERVICES::Execute", self.name, cmd)
    else
	if custom_service.has_key?(cmd) and !custom_service[cmd].blank?
	    command = custom_service[cmd]
	    Rails.logger.debug "Service commmand #{command}"
	    ret = Scr.instance.execute([command])
	else
	    raise Exception.new("Missing custom command to '#{cmd}' command")
	end
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
