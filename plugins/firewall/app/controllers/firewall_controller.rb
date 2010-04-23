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

require 'firewall'

class FirewallController < ApplicationController

  before_filter :login_required

  def show
    yapi_perm_check "firewall.read"
    firewall = Firewall.find

    respond_to do |format|
      format.xml { render  :xml => firewall.to_xml( :dasherize => false ) }
      format.json { render :json => firewall.to_json( :dasherize => false ) }
    end
  end

  def update
    root = params["firewall"]
    if root == nil || root == {}
      raise InvalidParameters.new :firewall => "Missing"
    end

    firewall = Firewall.new(root)
    yapi_perm_check "firewall.write"
    firewall.save

    show
  end

  # See update
  def create
    update
  end
end
