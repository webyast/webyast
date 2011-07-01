#--
# Webyast Webclient framework
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


# class for reading control panel configuration
# which is stored in /etc/webyast/control_panel.yml file
# The config file contains a single hash in YAML format.
class ControlPanelConfig

  # read a single value or complete control panel configuration
  # arguments:
  #   attribute => requested attribute name,
  #     if nil complete config is returned
  #   default_value => default value for the requested attribute,
  #     used when the attribute is missing or when an error occurrs
  #     during reading/parsing the config file
  def self.read(attribute = nil, default_value = nil)
    file	= '/etc/webyast/vendor/control_panel.yml'
    file	= '/etc/webyast/control_panel.yml' unless File.exists? file
    Rails.logger.info "Reading config file: #{file}"
    begin
      l = YAML::load_file file

      # no required attribute, return complete config
      return l if attribute.nil?

      # return requested attribute if present
      if l.has_key? attribute
        return l[attribute]
      end

      # return default for missing value
      Rails.logger.warn "Cannot read attribute '#{attribute}', using default: #{default_value}"
      return default_value
    rescue Exception => e
      Rails.logger.error "Cannot read #{file}: #{e}"
      return default_value
    end
  end
end
