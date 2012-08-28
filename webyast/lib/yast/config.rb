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

# = CONFIG
# the module provides constant for webyast configuration file:
# /etc/webyast/config.yml

require "yast/config_file"
def read_config(key = "")
  begin
    ret = YaST::ConfigFile.new(:config)
  rescue YaST::ConfigFile::NotFoundError
    ret = [] # treat absense as empty
  rescue Exception
    raise CorruptedFileException.new ret.path
  end
  unless (ret.blank? || key.blank?)
    begin
      ret = ret[key]
    rescue YaST::ConfigFile::NotFoundError
      ret = nil
    end
  end

  return ret
end

# TODO FIXME: use Yast module name here (compatible with Rails autoloading)
module YaST
  CONFIG=read_config()
  if ENV['WEBYAST_POLICYKIT']== 'true'
    POLKIT1 = false
  else
    POLKIT1 = read_config("polkit1") || true
  end
end

module Yast
  module Config
    config = read_config || {}

    # enabled when missing or invalid value
    WEB_UI_ENABLED = config["web_ui_enabled"] != false rescue true
    # disabled when missing or invalid value
    REST_API_ENABLED = !(config["rest_api_enabled"] != true) rescue false

    def self.web_ui_enabled
      WEB_UI_ENABLED
    end

    def self.rest_api_enabled
      REST_API_ENABLED
    end
  end
end

