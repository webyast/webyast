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

require 'yaml'
require 'exceptions'

# = Systemtime model
# Provides set and gets resources from YaPI time module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class Role < BaseModel::Base

attr_accessor :users
attr_accessor :permissions
attr_accessor :name
attr_writer :new_record
#specify serialized attributes to prevent new_record serialization
attr_serialized :users, :permissions, :name

ROLES_DEF_PATH = File.join Paths::VAR, "roles", "roles.yml"
ROLES_ASSIGN_PATH = File.join Paths::VAR, "roles", "roles_assign.yml"

def initialize(name="",permissions=[],users=[])
  @name = name
  @permissions = (permissions||[]).sort
  @users = (users||[]).sort
	@new_record = true
end

def new_record?
	@new_record
end

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

def update
	roles = Role.find_all
  old = roles[name]
	roles[name] = self
#if changed users renew its permissions
  if old.users.sort != @users.sort
    (@users+old.users).uniq.each do |user|
      Permission.set_permissions user, Role.permissions_for_user(roles.values,user)
    end
#if permissions in role is changed, then regenerate permission setup for each affected user
  elsif old.permissions.sort != @permissions.sort
    @users.each do |user|
      Permission.set_permissions user, Role.permissions_for_user(roles.values,user)
    end
  end

	Role.write_definitions roles.values
	Role.write_assigns roles.values
end

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

def self.delete (id)
	roles = find_all
	roles.delete id.to_s
	write_definitions roles.values
	write_assigns roles.values
end

def changed_users?
  old = Role.find @name
  return @users.sort != old.users.sort
end

def changed_permissions?
  old = Role.find @name
  return @permissions.sort != old.permissions.sort
end

private 
def self.find_all
  raise CorruptedFileException.new( ROLES_DEF_PATH ) unless File.exist? ROLES_DEF_PATH
  raise CorruptedFileException.new( ROLES_ASSIGN_PATH ) unless File.exist? ROLES_ASSIGN_PATH
  definitions = YAML::load( IO.read( ROLES_DEF_PATH ) ) || {}#FIXME convert yaml parse error to own exc
  result = {}
  definitions.each do |k,v|
    result[k] = Role.new( k, v )
		result[k].new_record = false #already known role
  end
  assigns = YAML::load( IO.read( ROLES_ASSIGN_PATH ) ) || {}
  assigns.each do |k,v|
    if result[k].nil? #incosistent files
			result[k] = Role.new(k)
			result[k].new_record = false
		end
    result[k].users = v.sort
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
