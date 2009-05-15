
 # import YastService class
require "yast_service"

class SambaShare

    attr_accessor   :name,
		    :parameters

    def initialize
	# share name
	@name = nil

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

	shares = [ ]

	share_names.each { |sh_name|
	    share = SambaShare.new
	    share.name = sh_name

	    shares << share
	}

	return shares
    end

    def find
	return false if @name.blank? 

	share_properties = YastService.Call("YaPI::Samba::GetShare", @name)

	if share_properties.nil? || share_properties == {}
	    @parameters = nil
	    return false
	else
	    @parameters = share_properties
	    return true
	end
    end

    def update_attributes(attribs)
	if attribs.has_key?(:name)
	    new_name = attribs[:name]

	    if new_name.class != :String
		return false
	    end

	    @name = new_name
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
	return YastService.Call("YaPI::Samba::AddShare", @name, @parameters) if !@name.blank?
	return false
    end

    def edit
	return YastService.Call("YaPI::Samba::EditShare", @name, @parameters) if !@name.blank?
	return false
    end

    def delete
	return YastService.Call("YaPI::Samba::DeleteShare", @name) if !@name.blank?
	return false
    end

    def to_xml( options = {} )
	return nil if @name.nil?

	xml = options[:builder] ||= Builder::XmlMarkup.new(options)
	xml.instruct! unless options[:skip_instruct]

	xml.share do
	    xml.tag!(:name, @name)

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
