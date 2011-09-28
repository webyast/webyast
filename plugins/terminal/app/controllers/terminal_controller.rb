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

class TerminalController < ApplicationController
  before_filter :login_required
  layout 'main'

  public
    #init_gettext "webyast-terminal"

  #TODO: USE HTTPS IMPORTANT!!!

  def index
    #TODO: CHECK PERMISSIONS
    @permissions = true
  end

  #TODO: START SHELLINABOX DEAMON ON THE FLY !!!
  #TODO: STOP SHELLINABOX DEAMON ON PAGE LEAVE ???

  #TODO: ALLOW USER TO CHANGE THEME, FONT SIZE and LOAD USER SETTINGS ON START UP
  #TODO: PROVIDE FUNCTIONALITY FOR MULTIOPLE TABS
end

