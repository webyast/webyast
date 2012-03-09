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

class RegistrationState
  def self.read()
    unless Register.new.is_registered?
      return { :level => "warning",
               :message_id => "MISSING_REGISTRATION",
               :short_description => _("Registration is missing"),
               :long_description => _("Please register your system in order to get updates."), # RORSCAN_ITL
               :confirmation_host => "client",
               :confirmation_link => "/registration",
               :confirmation_label => _("register"),
               :confirmation_kind => "link" } 
     else
       return {}
     end
  end
end
