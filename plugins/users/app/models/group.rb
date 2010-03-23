require 'yast_service'

# Group model, YastModel based
class Group < BaseModel::Base
  attr_accessor :cn              # group name
  attr_accessor :gid             # group number
  attr_accessor :old_cn          # for group identification when changing group name
  attr_accessor :default_members # list of user names, which have this group as default
  attr_accessor :members         # list of users explicitaly added into this group
  attr_accessor :type            # type of the group ... system or local

  attr_accessible :cn, :old_cn, :gid, :default_members, :members, :type

  validates_presence_of     :members
  validates_inclusion_of    :type, :in => ["system","local"]
  validates_format_of       :cn, :with => /[a-z]+/
  validates_format_of       :old_cn, :with => /[a-z]+/
  validates_numericality_of :gid

private

  def self.group_get(type,cn)
    Rails.logger.debug( 'YastService.Call("YaPI::USERS::GroupGet", {"type"=>["s","'+type+'"}], "cn"=>["s",'+cn.to_s+']})')
    YastService.Call("YaPI::USERS::GroupGet", {"type"=>["s",type], "cn"=>["s",cn]})
  end

  def self.groups_get(type)
    YastService.Call("YaPI::USERS::GroupsGet", {"type"=>["s",type]})
  end

  def self.make_group(group_hash)
    group_hash[:gid]             = group_hash["gidNumber"]
    group_hash[:cn]              = group_hash["cn"]
    group_hash[:old_cn]          = group_hash["cn"]
    group_hash[:default_members] = group_hash["more_users"].keys()
    group_hash[:members]         = group_hash["userlist"].keys()
    Group.new group_hash
  end

public

  def self.find (cn)
    result = group_get( "system", cn )
    result = group_get( "local", cn )  if result.empty?
    return nil if result.empty?
    make_group result
  end

  def self.find_all
    result = groups_get "local"
    result.update( groups_get "system")
    result.collect { |k,v| make_group v }
  end

  def save
    existing_group = Group.group_get( type, old_cn )
    if existing_group.empty?
      result = YastService.Call( "YaPI::USERS::GroupAdd",
                                 { "type"      => ["s", type] },
                                 { "cn"        => ["s",cn], "userlist"  => ["as", members] } )
    else
      result = YastService.Call( "YaPI::USERS::GroupModify",
                                 { "type"      => ["s", type],
                                   "cn"        => ["s", old_cn]  },
                                 { "gidNumber" => ["i", gid],
                                   "cn"        => ["s",cn],
                                   "userlist"  => ["as", members] } 
                               )
    end
    result # result is empty string on success, error message otherwise
  end

  def destroy
    existing_group = group_get( type, old_cn )
    if existing_group.empty?
      ""
    else
      YastService.Call( "YaPI::USERS::GroupDelete", {"type" => ["s",type], "cn" => ["s",old_cn]})
    end
  end
end
