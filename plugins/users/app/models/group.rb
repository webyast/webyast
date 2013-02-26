#--
# Copyright (c) 2009-2010 Novell, Inc.
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

require 'base'

# Group model, YastModel based
class Group < BaseModel::Base
  attr_accessor :cn              # group name
  attr_accessor :gid             # group number
  attr_accessor :old_cn          # for group identification when changing group name
  attr_accessor :default_members # list of user names, which have this group as default
  attr_writer   :members         # list of users explicitaly added into this group
  attr_accessor :group_type      # type of the group ... system or local # RORSCAN_ITL
  attr_accessor :members_string

  attr_accessible :cn, :old_cn, :gid, :default_members, :members, :group_type, :members_string

  validates_inclusion_of :group_type, :in => ["system","local"], :message=>"valid values are 'local' and 'system'"
  validates_format_of    :cn, :with => /[a-z]+/
  validates_format_of    :old_cn, :with => /[a-z]+/
  validates_numericality_of :gid, :only_integer=>true, :allow_nil => true,
    :greater_than_or_equal_to => 0, :less_than_or_equal_to => 65536 # cat /proc/sys/kernel/ngroups_max

  def members
    @members || []
  end

private

  def self.group_get(group_type, cn)
    args = {"type" => ["s", group_type], "cn" => ["s", cn]}
    Rails.logger.debug "YastService.Call(\"YaPI::USERS::GroupGet\", #{args.inspect})"
    YastService.Call("YaPI::USERS::GroupGet", args)
  end

  def self.groups_get(group_type)
    YastService.Call("YaPI::USERS::GroupsGet", {"type"=>["s",group_type], "index" => ["s","cn"]})
  end

  def self.make_group(group_hash)
    group_hash[:gid]             = group_hash["gidNumber"].to_i
    group_hash[:cn]              = group_hash["cn"]
    group_hash[:old_cn]          = group_hash["cn"]
    group_hash[:default_members] = group_hash["more_users"].keys()
    group_hash[:members]         = group_hash["userlist"].keys()
    group_hash[:group_type]      = group_hash["type"]
    group_hash[:members_string]  = group_hash[:members].join(",") unless group_hash[:members].blank?
    Group.new group_hash
  end

public

  def self.find (cn)
    return find_all if cn == :all
    result = group_get( "system", cn )
    result = group_get( "local", cn )  if result.empty?
    return nil if result.empty?
    make_group result
  end

  def self.find_all
    result = groups_get "local"
    result.update( groups_get "system")
    result_array = []
    result.each { |k,v| result_array << make_group(v) }
    result_array.sort! {|x,y| x.cn <=> y.cn}
  end

  def save
    if valid?
      existing_group = Group.group_get( group_type, old_cn )
      if existing_group.empty?
        result = YastService.Call( "YaPI::USERS::GroupAdd",
                                   { "type"      => ["s", group_type] },
                                   { "cn"        => ["s",cn], "userlist"  => ["as", members] } )
      else
        result = YastService.Call( "YaPI::USERS::GroupModify",
                                   { "type"      => ["s",  group_type],
                                     "cn"        => ["s",  old_cn]  },
                                   { "gidNumber" => ["i",  gid.to_i],
                                     "cn"        => ["s",  cn],
                                     "userlist"  => ["as", members] }
                                 )
      end
      result # result is empty string on success, error message otherwise
    else
      self.errors.full_messages.join ', '
    end
  end

  def destroy
    existing_group = Group.group_get( group_type, old_cn )
    if existing_group.empty?
      ret = ""
    else
      ret = YastService.Call( "YaPI::USERS::GroupDelete", {"type" => ["s",group_type], "cn" => ["s",old_cn]})
    end
    ret
  end

end
