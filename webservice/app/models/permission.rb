#
# Permission class
#

class Permission

  attr_reader :name, :grant

  def initialize( name = "", grant = false)
     @grant = grant
     @name = name
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.permission do
      xml.tag!(:name, @name )
      xml.tag!(:grant, @grant, {:type => "boolean"} )
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
