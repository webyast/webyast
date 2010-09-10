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

# simple ruby module for reading last n lines from given file
# files for reading are specified in the configuration file
# /etc/webyast/vendor/logs.yml
module LogFile

  def self.Read(id, pos_begin, lines)
    parsed	= {}
    file_name	= "/etc/webyast/vendor/logs.yml"
    file_name	= "/etc/webyast/logs.yml" unless File.exists?(file_name) # bnc#637398
    if File.exists?(file_name)
      parsed = YAML::load(File.open(file_name));
      parsed = {} unless parsed.is_a? Hash
    end

    unless parsed.has_key? id
      return "___WEBYAST___INVALID"
    end
    
    path = parsed[id]["path"]
    p_begin = pos_begin.to_i rescue 1 #if someone pass type which doesn't have to_i
    lcount = lines.to_i rescue 50 #if someone pass type which doesn't have to_i
    lcount = 50 if lcount<=0
    ret = `wc -l #{path}`
    file_length = ret.split()[0].to_i rescue 0 #if someone pass type which doesn't have to_i
    if p_begin > 0 && p_begin < file_length-lcount
      tail_pos = file_length-p_begin
    else
      tail_pos = lcount
    end
    #it is secure, because vendor specify path and lines is always number
    ret	= `tail -n #{tail_pos} #{path}|head -n #{lcount}`
    return {:value=>ret, :position=>"#{file_length-tail_pos}"}
  end
end
