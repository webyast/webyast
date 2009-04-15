class SystemTime

  attr_accessor :error_id, 
                :error_string,
                :currenttime,
                :timezone,
                :is_utc,
                :validtimezones

  def initialize 
     @error_id = 0
     @error_string = ""
     @currenttime = ""
     @timezone = ""
     @is_utc = false
     @validtimezones = ""
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.systemtime do
      xml.tag!(:currenttime, @currenttime, {:type=>"datetime"} )
      xml.tag!(:timezone, @timezone )
      xml.tag!(:is_utc, @is_utc, {:type => "boolean"} )
      xml.validtimezones({:type => "array"}) do
         @validtimezones.split( " " ).each do |timezone| 
            xml.timezone do
               xml.tag!(:id, timezone)
            end
         end
      end
      xml.tag!(:error_id, @error_id, {:type => "integer"} )
      xml.tag!(:error_string, @error_string )
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
