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

#caching makes no sense here cause the info comes from a Yaml file

require 'yaml'
require 'exceptions'
require 'base_model/base'
require 'webyast/paths'

# = Role model
# Provides information and editing of roles for webyast.
# Main goal is handle roles management. Use BaseModel.
class Role < BaseModel::Base

attr_accessor :users
attr_accessor :permissions
attr_accessor :name
attr_writer   :new_record
#specify serialized attributes to prevent new_record serialization
attr_serialized :users, :permissions, :name

# Path to roles definition file which contain role and its permissions
unless Rails.env.development?
  ROLES_DEF_PATH = File.join WebYaST::Paths::VAR, "roles", "roles.yml"
else
  ROLES_DEF_PATH = File.join(File.expand_path("../../../package", __FILE__), "roles.yml")
end

# Path to role assign file which contain role and users which has the role
unless Rails.env.development?
  ROLES_ASSIGN_PATH = File.join WebYaST::Paths::VAR, "roles", "roles_assign.yml"
else
  ROLES_ASSIGN_PATH = File.join(File.expand_path("../../../package", __FILE__), "roles_assign.yml")
end

def initialize(name="",permissions=[],users=[])
  @name = name
  @permissions = (permissions||[]).sort
  @users = (users||[]).sort
  @new_record = true
end

#own new_record specification to specify when create and when update is needed
def new_record?
  @new_record
end

# find role or roles
# what:: specificy role name or :all to get all roles
# options:: hash for future extension, not used yet
def self.find(what=:all,options={})
  result = find_all
  return case what
  when :all then
    result.values || []
  else
    v = result.find { |k,v| k.to_sym == what.to_sym }
    v[1] if v #return value, not key
  end
end

# Updates roles and permissions for users which loose, gain role or role
# change its permission
def update
  roles = Role.find_all
  old = roles[name]
  roles[name] = self
#if changed users renew its permissions
  if old.users.sort != @users.sort
    all_users = (@users+old.users).uniq
    intersect = @users&old.users
    affected_users = all_users.reject { |e| intersect.include? e }
    affected_users.each do |user|
      Permission.set_permissions user, Role.permissions_for_user(roles.values,user)
    end
  end
#if permissions in role is changed, then regenerate permission setup for each affected user
  if old.permissions.sort != @permissions.sort
    @users.each do |user|
      Permission.set_permissions user, Role.permissions_for_user(roles.values,user)
    end
  end

  Role.write_definitions roles.values
  Role.write_assigns roles.values
end

# Creates a new role and assign permissions for users which is in the role
def create
  roles = Role.find_all
  roles[name] = self
#set permission for users of new role
  @users.each do |user|
    Permission.set_permissions user, Role.permissions_for_user(roles.values,user)
  end
  Role.write_definitions roles.values
  Role.write_assigns roles.values
end

# Deletes role
# FIXME remove permissions from users in deleted role
def self.delete (id)
  roles = find_all
  roles.delete id.to_s
  write_definitions roles.values
  write_assigns roles.values
end

# Tests if users for role is changed
def changed_users?
  old = Role.find @name
  return @users.sort != old.users.sort
end

# Tests if permissions for role is changed
def changed_permissions?
  old = Role.find @name
  return @permissions.sort != old.permissions.sort
end

private 
def self.find_all
#  raise CorruptedFileException.new( ROLES_DEF_PATH ) unless File.exist? ROLES_DEF_PATH
#  raise CorruptedFileException.new( ROLES_ASSIGN_PATH ) unless File.exist? ROLES_ASSIGN_PATH
  result = {}

  begin
    definitions = YAML::load( IO.read( ROLES_DEF_PATH ) ) || {}#FIXME convert yaml parse error to own exc
    definitions.each do |k,v|
      result[k] = Role.new( k, v )
      result[k].new_record = false #already known role
    end
  rescue IOError,SystemCallError
    raise CorruptedFileException.new( ROLES_DEF_PATH )
  end

  begin
    assigns = YAML::load( IO.read( ROLES_ASSIGN_PATH ) ) || {}
    assigns.each do |k,v|
      if result[k].nil? #incosistent files
        result[k] = Role.new(k)
        result[k].new_record = false
      end
      result[k].users = v.sort
    end
  rescue IOError,SystemCallError
    raise CorruptedFileException.new( ROLES_ASSIGN_PATH )
  end

  return result
end

def self.write_definitions(roles)
  result = {}
  roles.each do |v|
    result[v.name] = v.permissions
  end
  File.open ROLES_DEF_PATH, "w" do |io|
   io.write result.to_yaml
  end
end

def self.write_assigns(roles)
  result = {}
  roles.each do |v|
    result[v.name] = v.users
  end
  File.open ROLES_ASSIGN_PATH, "w" do |io|
    io.write result.to_yaml
  end
end

def self.permissions_for_user(roles,user)
  permissions = []
  roles.each do |role|
    if role.users.include? user
      permissions.concat role.permissions
    end
  end
  permissions.uniq
end

end
