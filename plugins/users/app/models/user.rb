
class User
  
  attr_accessor :cn,
                :uid,
                :uidNumber,
		:gidNumber,
                :grouplist,
		:groupname,
		:homeDirectory,
		:loginShell,
		:userPassword,
		:addit_data,
		:type,
                :sshkey

  def id
    @uid
  end

  def id=(id_val)
    @uid	= id_val
  end
  
  def initialize 
    @cn			= ""
    @uid		= ""
    @uidNumber		= ""
    @grouplist		= {}
    @groupname		= ""
    @homeDirectory	= ""
    @loginShell		= ""
    @userPassword	= ""
    @type		= "local"
    @sshkey		= ""
  end

  def update_attributes usr
    return false if usr==nil
    @grouplist		= usr[:grouplist]
    @homeDirectory	= usr[:homeDirectory]
    @type		= usr[:type]
    @groupname		= usr[:groupname]
    @loginShell		= usr[:loginShell]
    @userPassword	= usr[:userPassword]
    @uid		= usr[:uid]
    @uidNumber		= usr[:uidNumber]
    @cn			= usr[:cn]

    @sshkey 		= usr[:sshkey]
    return true
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    
    xml.user do
      xml.tag!(:id, id )
      xml.tag!(:cn, cn )
      xml.tag!(:groupname, groupname)
      xml.tag!(:homeDirectory, homeDirectory )
      xml.tag!(:loginShell, loginShell )
      xml.tag!(:uid, uid )
      xml.tag!(:uidNumber, uidNumber, {:type => "integer"})
      xml.tag!(:userPassword, userPassword )
      xml.tag!(:type, type )
      xml.tag!(:sshkey, sshkey )
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
