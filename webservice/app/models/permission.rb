#
# Permission class
#

class Permission

  attr_accessor :name,
                :grant

  def initialize( permission_name = "", gr = false)
     @grant = gr
     @name = permission_name
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
