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

class NotifierController < ApplicationController

  # GET /notifier
  # GET /notifier.xml
  def status
    id = params[:id] || :all

    # FIXME: temporarily disabled
    if true
      head :not_found and return
    else
      # TODO handle missing parameter
      updated = params[:plugin].split(",").any? { |model|
         DataCache.updated?(model, id, session["session_id"])
      }

      head updated ? :ok : :not_modified
    end
  end

  # GET /notifier
  # GET /notifier.xml
  def index
    status
  end
end
