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

require 'gettext'

class PatchesState
  include GetText
  def self.read()
    if File.exist? Patch::MESSAGES_FILE
      f = File.new(Patch::MESSAGES_FILE, 'r')
      messages = f.gets(nil) || ""

      return { :level => "warning",
               :message_id => "PATCH_MESSAGES",
               :short_description => _("Patch installation messages not confirmed"),
               :long_description => messages,
	       :details	=> "",
               :confirmation_host => "service",
               :confirmation_link => "/patch_update/state",
               :confirmation_label => _("OK"),
               :confirmation_kind => "button" } 
    else
      return {}
    end   
  end
end
