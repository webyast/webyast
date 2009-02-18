class ConfigNtp 

  attr_accessor :error_id, 
                :error_string,
                :enabled,
                :use_random_server,
                :manual_server

  def initialize 
     @error_id = 0
     @error_string = ""
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
      xml.tag!(:error_id, @error_id, {:type => "integer"} )
      xml.tag!(:error_string, @error_string )
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
