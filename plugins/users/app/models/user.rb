
class User
  
  attr_accessor :cn,
                :uid,
                :uid_number,
		:gid_number,
                :grouplist,
		:groupname,
		:home_directory,
		:login_shell,
		:user_password,
		:addit_data,
		:type

  def id
    @uid
  end

  def id=(id_val)
    @uid	= id_val
  end
  
  def initialize 
    @cn			= ""
    @uid		= ""
    @uid_number		= ""
    @gid_number		= ""
    @grouplist		= {}
    @groupname		= ""
    @home_directory	= ""
    @login_shell		= ""
    @user_password	= ""
    @type		= "local"
  end

  def update_attributes usr
    return false if usr==nil
    @grouplist		= usr[:grouplist]
    @home_directory	= usr[:home_directory]
    @type		= usr[:type]
    @groupname		= usr[:groupname]
    @login_shell		= usr[:login_shell]
    @user_password	= usr[:user_password]
    @uid		= usr[:uid]
    @uid_number		= usr[:uid_number]
    @gid_number		= usr[:gid_number]
    @cn			= usr[:cn]

    return true
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
