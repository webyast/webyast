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


#  config.action_controller.session = {
#    :key => '_yast-api_session',
#    # It is overwritten during install time (bnc#550635), do not change key # RORSCAN_INL
#    :secret      => '9d11bfc98abcf9799082d9c34ec94dc1cc926f0f1bf4bea8c440b497d96b14c1f712c8784d0303ee7dd69e382c3e5e4d38d4c56d1b619eae7acaa6516cd733b1'
#  }

Webyast::Application.config.session_store :cookie_store, :key=> '_webyast_session'
#Rails.application.config.cookie_secret = '9d11bfc98abcf9799082d9c34ec94dc1cc926f0f1bf4bea8c440b497d96b14c1f712c8784d0303ee7dd69e382c3e5e4d38d4c56d1b619eae7acaa6516cd733b1'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Webyast::Application.config.session_store :active_record_store

