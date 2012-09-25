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

class Account < ActiveRecord::Base
  # timeout for valid auth token
  # use the same time as for session time out
  TOKEN_AUTH_TIMEOUT = Devise.timeout_in

  devise :unix2_chkpwd_authenticatable, 
         :timeoutable, :token_authenticatable

  # do not pass expired authentication token
  def authentication_token
    token_expired? ? nil : self[:authentication_token]
  end

  def token_expired?
    # expired if the account was updated (token created) long time ago
    updated_at < TOKEN_AUTH_TIMEOUT.ago
  end

  # time when the token expires (or expired)
  def token_expires_at
    authentication_token ? updated_at + TOKEN_AUTH_TIMEOUT : nil
  end
end

