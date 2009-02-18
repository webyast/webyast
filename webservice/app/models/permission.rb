class Permission

  attr_accessor :error_id, 
                :error_string,
                :name,
                :grant

  def initialize( permission_name = "", gr = false)
     @error_id = 0
     @error_string = ""
     @grant = gr
     @name = permission_name
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.permission do
      xml.tag!(:name, @name )
      xml.tag!(:grant, @grant, {:type => "boolean"} )
      xml.tag!(:error_id, @error_id, {:type => "integer"} )
      xml.tag!(:error_string, @error_string )
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
