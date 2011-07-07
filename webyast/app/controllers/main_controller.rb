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

#
# Main
#
# This is the default controller for webclient
#
# It will check if a session is established
# and redirect to ControlPanel.index or Session.new
#

class MainController < ApplicationController
  def index
    
    redirect_to(logged_in? ?
		{ :controller => "controlpanel", :action => "index" } :
		{ :controller => "session", :action => "new" })
  end

  # POST /select_language
  # setting language for translations
  def select_language
    render :partial => "select_language" 
  end

end
