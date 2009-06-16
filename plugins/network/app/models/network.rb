class Network
  require "scr"

  attr_accessor	:network,
		:id,
		:name,
		:description,
		:mac,
		:dev_name,
		:startup
	

  def to_json(options = {})
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

  def initialize
    @scr = Scr.instance
  end


  def Network.find_all()
     ret = Scr.instance.execute(["/sbin/yast2", "lan", "list"])
     lines = ret[:stderr].split "\n"
     devices = []
     lines.each do |s|   
        dev = Network.new
	dev.id = s.split("\t")[0]
        dev.name = s.split("\t")[1]
        devices << dev
     end
     return devices
  end


  def to_xml( options = {} )
      return nil if @id.nil?

      xml = options[:builder] ||= Builder::XmlMarkup.new(options)
      xml.instruct! unless options[:skip_instruct]

      xml.device do
          xml.tag!(:id, @id)
          xml.tag!(:name, @name) if !@name.nil?
          xml.tag!(:description, @description) if !@description.nil?
          xml.tag!(:mac, @mac) if !@mac.nil?
          xml.tag!(:dev_name, @dev_name) if !@dev_name.nil?
          xml.tag!(:startup, @startup) if !@startup.nil?

          if !@parameters.blank?
              @parameters.each do |key,value|
                  xml.parameters {
                      xml.tag!(:name, key)
                      xml.tag!(:value, value)
                  }
              end
          end
      end
   end


end


