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

  def self.group_get(type,gid)
    Rails.logger.debug( 'YastService.Call("YaPI::USERS::GroupGet", {"type"=>["s","'+type+'"}], "gidNumber"=>["i",'+gid.to_s+']})')
    YastService.Call("YaPI::USERS::GroupGet", {"type"=>["s",type], "gidNumber"=>["i",gid]})
  end

  def self.groups_get(type)
    YastService.Call("YaPI::USERS::GroupsGet", {"type"=>["s",type]})
  end

  def self.make_group(group_hash)
    group_hash[:gid]             = group_hash["gidNumber"]
    group_hash[:old_gid]         = group_hash["gidNumber"]
    group_hash[:default_members] = group_hash["more_users"].keys()
    group_hash[:members]         = group_hash["userlist"].keys()
    Group.new group_hash
  end

public

  def self.find (gid)
    gid = gid.to_i
    result = group_get( "system", gid )
    result = group_get( "local", gid )  if result.empty?
    return nil if result.empty?
    make_group result
  end

  def self.find_all
    result = groups_get "local"
    result.update( groups_get "system")
    result.collect { |k,v| make_group v }
  end

  def save
    existing_group = group_get( type, old_gid )
    if existing_group.empty?
      result = YastService.Call( "YaPI::USERS::GroupAdd",
                                 { "type"      => ["s", type] },
                                 { "cn"        => ["s",cn], "userlist"  => ["as", members] } )
    else
      result = YastService.Call( "YaPI::USERS::GroupModify",
                                 { "type"      => ["s", type],
                                   "gidNumber" => ["i", old_gid]  },
                                 { "gidNumber" => ["i", gid],
                                   "cn"        => ["s",cn],
                                   "userlist"  => ["as", members] } 
                               )
    end
    if ! result.empty?
      raise result # result is empty string on success, error message otherwise
    end
  end
end
