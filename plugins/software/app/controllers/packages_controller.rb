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

require 'singleton'

class PackagesController < ApplicationController

   # always check permissions
   before_filter :check_read_permissions, :only => {:index, :show}

  private

  def check_read_permissions
    authorize! :read, Patch
  end

  def compare_lists(packages)
    vendor_packages = Array.new
    #TODO: replace by real yml file
    package_list = ["3ddiag", "foo", "yast2-users", "yast2-network"]

    package_list.each {|pk_name|
      p = packages.find { |pkg| pk_name == pkg.name }
      p ||= Package.new(:resolvable_id => 0, :name => pk_name, :version => "not_installed")
      vendor_packages << p
    }

    vendor_packages
  end

  public

  # GET /packages
  # GET /packages.xml
  def index
    # note: permission check was performed in :before_filter
    @packages = Package.find(:installed)
    if params[:filter] == "custom"
      @packages = compare_lists(@packages)
    end
    respond_to do |format|
      format.xml { render  :xml => @packages.to_xml( :root => "packages", :dasherize => false ) }
      format.json { render :json => @packages.to_json( :root => "packages", :dasherize => false ) }
    end
  end

  # GET /packages/1
  # GET /packages/1.xml
  def show
  end

  # PUT /packages/1
  # PUT /packages/1.xml
  def update
  end

end
