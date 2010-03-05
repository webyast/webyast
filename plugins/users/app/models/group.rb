require 'yast_service'

# User model, not ActiveRecord based, but a
# thin model over the YaPI, with some
# ActiveRecord like convenience API
class Group
  
  attr_accessor_with_default :allgroups, {}

  def initialize    
  end
  
  # load the attributes of the user
  def self.find()
    group = Group.new

    system_groups = YastService.Call("YaPI::USERS::GroupsGet", {"index"=>["s","cn"],"type"=>["s","system"]})
    local_groups = YastService.Call("YaPI::USERS::GroupsGet", {"index"=>["s","cn"],"type"=>["s","local"]})
    group.allgroups = Hash[*(local_groups.keys | system_groups.keys).collect {|v| [v,1]}.flatten]

    group
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    
    xml.user do
      xml.allgroups({:type => "array"}) do
         allgroups.each do |group| 
	    xml.group do
	      xml.tag!(:cn, group[0])
	    end
         end
      end
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
