class Patch

  attr_accessor   :resolvable_id,
                  :kind,
                  :name,
                  :arch,
                  :repo,
                  :summary

  def id
    @resolvable_id
  end

  def id=(id_val)
    @resolvable_id = id_val
  end

  def initialize 
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.patch_update do
      xml.tag!(:id, id )
      xml.tag!(:resolvable_id, @resolvable_id, {:type => "integer"} )
      xml.tag!(:kind, @kind )
      xml.tag!(:name, @name )
      xml.tag!(:arch, @arch )
      xml.tag!(:repo, @repo )
      xml.tag!(:summary, @summary )
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
