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


class RestdocController < ApplicationController
  def index
    @restdocs = Restdoc.find :all
    Rails.logger.debug "Found restdoc files: #{@restdocs.inspect}"
  end

  def show
    @restdoc = Restdoc.find param[:id]

    #TODO FIXME
    # find the webyast engine and render the file
    # render :file => "#{@restdoc}crm_api/index.html", :layout => true

    # TODO FIXME serve *.xml files via static middleware:
    # http://jonswope.com/2010/07/25/rails-3-engines-plugins-and-static-assets/
  end
end
