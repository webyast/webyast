class Links

  attr_accessor :path,
                :description,
                :read_permission,
                :write_permission,
                :execute_permission,
                :delete_permission,
                :install_permission,
                :new_permission

  def initialize 
     @path = ""
     @description = ""
     @read_permission = false
     @write_permission = false
     @execute_permission = false
     @delete_permission = false
     @install_permission = false
     @new_permission = false
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.link do
      xml.tag!(:path, @path)
      xml.tag!(:description, @description)
      xml.tag!(:read_permission, @read_permission, {:type => "boolean"} )
      xml.tag!(:write_permission, @write_permission, {:type => "boolean"} )
      xml.tag!(:execute_permission, @execute_permission, {:type => "boolean"} )
      xml.tag!(:delete_permission, @delete_permission, {:type => "boolean"} )
      xml.tag!(:install_permission, @install_permission, {:type => "boolean"} )
      xml.tag!(:new_permission, @new_permission, {:type => "boolean"} )
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end


end
