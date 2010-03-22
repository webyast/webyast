require 'yast_service'

# Group model, YastModel based
class Group < BaseModel::Base
  attr_accessor :cn              # group name
  attr_accessor :gid             # group number
  attr_accessor :old_gid         # for group identification when changing group id
  attr_accessor :default_members # list of user names, which have this group as default
  attr_accessor :members         # list of users explicitaly added into this group
  attr_accessor :type            # type of the group ... system or local

  attr_accessible :cn, :gid, :old_gid, :default_members, :members, :type

  validates_presence_of     :members
  validates_inclusion_of    :type, :in => ["system","local"]
  validates_format_of       :cn, :with => /[a-z]+/
  validates_numericality_of :gid
  validates_numericality_of :old_gid

private

  def group_get(type,gid)
    YastService.Call("YaPI::USERS::GroupGet", {"type"=>["s",type], "gidNumber"=>["i",gid]})
  end

public:

  def self.find (gid)
    result = group_get ("system", gid)
    result = group_get ("local", gid)  if result.empty?
    return nil if result.empty?
    result[:gid]             = result["gidNumber"]
    result[:old_gid]         = result["gidNumber"]
    result[:default_members] = result["more_users"].keys()
    result[:members]         = result["listusers"].keys()
    Group.new result
  end

  def save
    result = YaSTService.Call("YaPI::USERS::GroupModify"
                             , { "type"      => ["s", type],
                                 "gidNumber" => ["i", old_gid]  }
                             , { "gidNumber" => ["i", gid],
                                 "cn"        => ["s",cn],
                                 "listusers" => ["as", members] } 
                             )
    if ! result.empty?
      raise result # result is empty string on success, error message otherwise
    end
  end
end
