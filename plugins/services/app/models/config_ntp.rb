class ConfigNtp 

  attr_accessor :enabled,
                :use_random_server,
                :manual_server

  def initialize 
     @enabled = false
     @use_random_server = false
     @manual_server = ""
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.config_ntp do
      xml.tag!(:manual_server, @manual_server )
      xml.tag!(:enabled, @enabled, {:type => "boolean"} )
      xml.tag!(:use_random_server, @use_random_server, {:type => "boolean"} )
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
