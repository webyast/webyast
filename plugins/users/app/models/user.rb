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

require 'yast_service'
require 'yast_cache'
require 'base'
require 'builder'

# User model, not ActiveRecord based, but a
# thin model over the YaPI, with some
# ActiveRecord like convenience API
class User < BaseModel::Base
  
  attr_writer :cn, :uid, :uid_number, :gid_number, :grouplist, :groupname, :home_directory, :login_shell, 
              :user_password, :user_password2, :type, :grp_string, :roles_string


  def cn
    @cn ||  ""
  end
  def uid
    @uid || ""
  end
  def uid_number
    @uid_number || ""
  end
  def gid_number
    @gid_number || ""
  end
  def grouplist
    @grouplist || {}
  end
  def groupname
    @groupname || ""
  end
  def home_directory
    @home_directory || ""
  end
  def login_shell
    @login_shell || "/bin/bash"
  end
  def user_password
    @user_password || ""
  end
  def user_password2
    @user_password2 || ""
  end
  def type
    @type || "local"
  end
  def grp_string
    @grp_string || ""
  end
  def roles_string
    @roles_string || ""
  end

public

  def initialize    
  end
  
  # users = User.find_all
  def self.find_all(params={})
    YastCache.fetch(self, :all) {
      attributes = [ "cn", "uidNumber", "homeDirectory", "grouplist", "uid", "loginShell", "groupname" ]
      if params.has_key? "attributes"
        attributes = params["attributes"].split(",")
      end
      users = []
      parameters = {
        # how to index hash with users
        "index"	=> ["s", "uid"],
        # attributes to return for each user
        "user_attributes"	=> [ "as", attributes ],
        "type" => params["type"]||="local"
      }
      users_map = YastService.Call("YaPI::USERS::UsersGet", parameters)
      if users_map.nil?
        raise "Can't get user list"
      else
        users_map.each do |key, val|
          user = User.new
          user.load_data(val)
          users << user
        end
      end
      users
    }
  end

  # load the attributes of the user
  def self.find(id)

    return find_all if id == :all

    user = User.new
    parameters	= {
        # user to find
        "uid" => [ "s", id ],
        # list of attributes to return;
        "user_attributes" =>
          [ "as", [ "cn", "uidNumber", "homeDirectory",
                  "grouplist", "uid", "loginShell", "groupname" ] ]
    }
    user_map = YastService.Call("YaPI::USERS::UserGet", parameters)
    raise "Got no data while loading user attributes" if user_map.empty?

    user.load_data(user_map)
    user.uid = id
    user
  end

  # User.destroy("joe")
  def self.destroy(uid)
    # delete existing local user
    config = {
      "type" => [ "s", "local" ],
      "uid" => [ "s", uid ],
      "delete_home" => [ "b", true ]
    }

    ret = YastService.Call("YaPI::USERS::UserDelete", config)
    Rails.logger.debug "Command returns: #{ret}"
    YastCache.delete(self, uid)
    raise ret unless ret.blank?
    return true
  end

  # user.destroy
  def destroy
    self.class.destroy(uid)
  end

  def save(id)
    config = {
      "type" => [ "s", "local" ],
      "uid" => [ "s", id ]
    }
    data = retrieve_data
    ret = YastService.Call("YaPI::USERS::UserModify", config, data)

    Rails.logger.debug "Command returns: #{ret.inspect}"
    YastCache.reset(self, id)
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
    load_attributes(attrs)
  end

#XXX USE base model which already contain such functionality it automatic
ATTR_ACCESSIBLE = [:cn, :uid, :uid_number, :gid_number, :grouplist, :groupname,
                :home_directory, :login_shell, :user_password, :type ]
  # load a hash of attributes
  def load_attributes(attrs)
    return false if attrs.nil?
    attrs.each do |key, value|
      if ATTR_ACCESSIBLE.include?(key.to_sym)
        self.send("#{key}=".to_sym, value)
      end
    end
    true
  end

  # retrieves the internally used data
  # hash with camel-cased values
  def retrieve_data
    data = { }
    if self.respond_to?(:grouplist)
	attr = self.grouplist
	groups	= {}
	attr.keys.each do |cn|
	  groups[cn]	= ["i",1]
	end
	data.store("grouplist", ["a{sv}",groups])
    end
    [ :cn, :uid, :uid_number, :gid_number, :groupname, :home_directory, :login_shell, :user_password, :addit_data, :type ].each do |attr_name|
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
    user.grouplist = {}
    unless user.grp_string.blank?
       user.grp_string.split(",").each do |groupname|
	  group = { "cn" => groupname.strip }
	  user.grouplist.push group
       end
    end

    data = user.retrieve_data
    
    config.store("type", [ "s", "local" ])
    data.store("uid", [ "s", user.uid])

    ret = YastService.Call("YaPI::USERS::UserAdd", config, data)

    Rails.logger.debug "Command returns: #{ret.inspect}"
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
         grouplist.each do |group| 
	    xml.group do
	      xml.tag!(:cn, group[0])
	    end
         end
      end
    end  
  end

  def to_json( options = {} )
    gr_list=[]
    grouplist.keys.each do |group|
     gr_list.push( :cn=> group )
    end
    hash = {
	:id => id,
	:cn => cn,
        :groupname => groupname,
        :gid_number => gid_number,
        :home_directory => home_directory,
        :login_shell => login_shell,
        :uid => uid,
        :uid_number => uid_number,
        :user_password => user_password,
        :type => type,
	:grouplist => gr_list
	}
    return hash.to_json
  end

end
