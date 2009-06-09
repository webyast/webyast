
# import YastService class
require "yast_service"

class SambaShare

    attr_accessor   :id,
		    :parameters

    def initialize
	# share name = id
	@id = nil

	# attributes
	@parameters = nil
    end

    # smb.conf uses "yes/no", "true/false" and "1/0" boolean values, the strings are case insensitive
    def SambaShare.isSMBtrue?(bool)
	return (bool == true || bool.downcase == "yes" || bool.downcase == "true" || bool == "1" || bool == 1)
    end

    def SambaShare.find_all()
	# read all share names
	share_names = YastService.Call("YaPI::Samba::GetAllDirectories")
	share_names.sort!

	shares = [ ]

	share_names.each { |sh_name|
	    share = SambaShare.new
	    share.id = sh_name

	    shares << share
	}

	return shares
    end

    def find
	return false if @id.blank? 

	share_properties = YastService.Call("YaPI::Samba::GetShare", @id)

	if share_properties.nil? || share_properties == {}
	    @parameters = nil
	    return false
	else
	    @parameters = share_properties
	    return true
	end
    end

    def update_attributes(attribs)
	return false if attribs.nil?

	if attribs.has_key?(:id)
	    new_name = attribs[:id]

	    if new_name.class != :String
		return false
	    end

	    @id = new_name
	end

	if attribs.has_key?(:parameters)
	    new_params = attribs[:parameters]

	    if new_params.class != :Hash
		return false
	    end

	    @parameters = new_params
	end

	return true
    end

    def add
	return YastService.Call("YaPI::Samba::AddShare", @id, @parameters) if !@id.blank?
	return false
    end

    def edit
	return YastService.Call("YaPI::Samba::EditShare", @id, @parameters) if !@id.blank?
	return false
    end

    def delete
	return YastService.Call("YaPI::Samba::DeleteShare", @id) if !@id.blank?
	return false
    end

    def to_xml( options = {} )
	return nil if @id.nil?

	xml = options[:builder] ||= Builder::XmlMarkup.new(options)
	xml.instruct! unless options[:skip_instruct]

	xml.share do
	    xml.tag!(:id, @id)

	    if !@parameters.blank?
		xml.parameters {
		    @parameters.each do |key,value|
			xml.parameter {
			    xml.tag!(:name, key)
			    xml.tag!(:value, value)
			}
		    end
		}
	    end
	end
    end

    def to_json( options = {} )
	hash = Hash.from_xml(to_xml())
	return hash.to_json
    end

end

# vim: ft=ruby
