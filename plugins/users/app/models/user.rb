
class User
  
  attr_accessor :full_name,
                :groups,
                :default_group,
                :home_directory,
                :login_name,
                :login_shell,
                :uid,
                :password,
                :ldap_password,
                :type,
                :new_uid,
                :new_login_name,
                :no_home,
                :sshkey

  def id
    @login_name
  end

  def id=(id_val)
    @login_name = id_val
  end
  
  def initialize 
    @no_home = false
    @full_name = ""
    @groups = ""
    @default_group = ""
    @home_directory = ""
    @login_shell = ""
    @login_name = ""
    @uid = ""
    @password = ""
    @ldap_password = ""
    @type = ""
    @new_uid = ""
    @new_login_name = ""
    @sshkey = ""
  end

  def update_attributes usr
    return false if usr==nil
    @no_home = usr[:no_home]
    @groups = usr[:groups]
    @home_directory = usr[:home_directory]
    @type = usr[:type]
    @new_login_name = usr[:new_login_name]
    @default_group = usr[:default_group]
    @login_name = usr[:login_name]
    @uid = usr[:uid]
    @ldap_password = usr[:ldap_password]
    @login_shell = usr[:login_shell]
    @full_name = usr[:full_name]
    @password = usr[:password]
    @new_uid = usr[:new_uid]
    @sshkey = usr[:sshkey]
    return true
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    
    xml.user do
      xml.tag!(:id, id )
      xml.tag!(:full_name, full_name )
      xml.tag!(:no_home, no_home, {:type => "boolean"} )
      xml.tag!(:default_group, default_group )
      xml.tag!(:home_directory, home_directory )
      xml.tag!(:login_shell, login_shell )
      xml.tag!(:login_name, login_name )
      xml.tag!(:uid, uid, {:type => "integer"})
      xml.tag!(:password, password )
      xml.tag!(:ldap_password, ldap_password )
      xml.tag!(:type, type )
      xml.tag!(:new_uid, new_uid )
      xml.tag!(:new_login_name, new_login_name )
      xml.tag!(:sshkey, sshkey )
      xml.groups({:type => "array"}) do
         groups.split( "," ).each do |group| 
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
