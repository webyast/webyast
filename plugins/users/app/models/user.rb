
require 'yast_service'

# User model, not ActiveRecord based, but a
# thin model over the YaPI, with some
# ActiveRecord like convenience API
class User
  
  attr_accessor_with_default :cn, ""
  attr_accessor_with_default :uid, ""
  attr_accessor_with_default :uid_number, ""
  attr_accessor_with_default :gid_number, ""
  attr_accessor_with_default :grouplist, {}
  attr_accessor_with_default :groupname, ""
  attr_accessor_with_default :home_directory, ""
  attr_accessor_with_default :login_shell, ""
  attr_accessor_with_default :user_password, ""
  attr_accessor_with_default :type, "local"

  def initialize    
  end
  
  # users = User.find_all
  def self.find_all
    users = []
    parameters	= {
      # how to index hash with users
      "index"	=> ["s", "uid"],
      # attributes to return for each user
      "user_attributes"	=> ["as", [ "cn" ]]
    }
    users_map = YastService.Call("YaPI::USERS::UsersGet", parameters)
    if users_map.nil?
      raise "Can't get user list"
    else
      users_map.each do |key, val|
        user = User.new
        user.uid = key
        user.cn = val["cn"]
        users << user
      end
    end
    users
  end

  # load the attributes of the user
  def self.find(id)
    user = User.new
    parameters	= {
      # user to find
      "uid" => [ "s", id ],
      # list of attributes to return;
      "user_attributes"	=>
        [ "as", [ "cn", "uidNumber", "homeDirectory",
                  "grouplist", "uid", "loginShell", "groupname" ] ]
    }
    user_map = YastService.Call("YaPI::USERS::UserGet", parameters)

    raise "Got no data while loading user attributes" if user_map.empty?

    load_data(user_map)
    user.uid = id
  end

  # User.destroy("joe")
  def self.destroy(uid)
    # delete existing local user
    config = {
      "type" => [ "s", "local" ],
      "uid" => [ "s", uid ]
    }

    ret = YastService.Call("YaPI::USERS::UserDelete", config)
    Rails.logger "Command returns: #{ret}"
    # @error_string = ret
    return (ret == "")
  end

  # user.destroy
  def destroy
    self.class.destroy(uid)
  end

  def save
    config = { "type" => [ "s", "local" ],
      "uid" => [ "s", @user.uid ]
    }
    data = retrieve_data
    ret = YastService.Call("YaPI::USERS::UserModify", config, data)

    logger.debug "Command returns: #{ret.inspect}"
    raise ret if not ret.blank?
    true
  end
  
  # load a internally used data hash
  # with camel-cased values
  def load_data(data)
    attrs = {}
    data.each do |key, value|
      attrs.store(key.underscore, value)
    end
    load_attribures(attrs)
  end

  # load a hash of attributes
  def load_attributes(attrs)
    return false if attrs.nil?
    attrs.each do |key, value|
      if self.respond_to?(key.to_sym)
        self.send("#{key}=".to_sym, value)
      end
    end
    true
  end

  # retrieves the internally used data
  # hash with camel-cased values
  def retrieve_data
    data = { }
    [ :cn, :uid, :uid_number, :gid_number, :grouplist, :groupname, :home_directory, :login_shell, :user_password, :addit_data, :type ].each do |attr_name|
      if self.respond_to?(attr_name)
        attr = self.send(attr_name)
        data.store(attr_name.to_s.camelize(:lower), ['s', attr]) unless attr.blank?
      end
    end
    data
  end
    
  # create a user in the local system
  def self.create(attrs)
    config = {}
    user = User.new
    user.load_attributes(attrs)
    data = user.retrieve_data
    
    config.store("type", [ "s", "local" ])
    data.store("uid", [ "s", user.uid])

    ret = YastService.Call("YaPI::USERS::UserAdd", config, data)

    Rails.logger.debug "Command returns: #{ret.inspect}"
    # @error_string = ret
    raise ret if not ret.blank?
    user
  end
  
  def id
    @uid
  end

  def id=(id_val)
    @uid = id_val
  end
  

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    
    xml.user do
      xml.tag!(:id, id )
      xml.tag!(:cn, cn )
      xml.tag!(:groupname, groupname)
      xml.tag!(:gid_number, gid_number, {:type => "integer"})
      xml.tag!(:home_directory, home_directory )
      xml.tag!(:login_shell, login_shell )
      xml.tag!(:uid, uid )
      xml.tag!(:uid_number, uid_number, {:type => "integer"})
      xml.tag!(:user_password, user_password )
      xml.tag!(:type, type )
      xml.grouplist({:type => "array"}) do
         grouplist.each do |group, val| 
            xml.group do
               xml.tag!(:id, group)
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
