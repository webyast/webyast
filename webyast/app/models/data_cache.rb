#--
# Webyast framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

#
# DataCache class
#

require 'static_record_cache'

class DataCache < ActiveRecord::Base
  acts_as_static_record

  def DataCache.extract_path_args(path)
    path_array = path.split(":")
    ret_array = path_array[0,2]
    if path_array.size >= 3
      ret_array << path_array[2]
    end
    ret_array.join(":")
  end

  def DataCache.find_by_path(path)
    data_cache = DataCache.find(:all) || [] #only find:all is cached
    data_cache.delete_if{ |item|
      self.extract_path_args(item.path) != self.extract_path_args(path)
    }
  end

  def DataCache.find_by_path_and_session(path,session)
    data_cache = DataCache.find(:all) || [] #only find:all is cached
    data_cache.delete_if{ |item|
      self.extract_path_args(item.path) != self.extract_path_args(path) || item.session != session 
    }
  end

  def self.updated?(model, id, session)
    path = YastCache.find_key(model, id)
    raise InvalidParameters.new({ :description => "Model #{model.inspect} not found on service side" }) if path.blank?
    data_cache = DataCache.find_by_path_and_session(path,session)
    data_cache.each { |cache|
      return true if !cache.refreshed_md5.blank? && cache.picked_md5 != cache.refreshed_md5
    } unless data_cache.blank?
    return false
  end
end
