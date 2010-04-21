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

# = Base system controller
# Provides access to queue for basic system setup.
# It is really quite thin layer.
class BasesystemController < ApplicationController

  before_filter :login_required

   def show
     basesystem = Basesystem.find
     logger.warn "No steps defined for Basesystem" if basesystem.steps.nil? or basesystem.steps.empty?
     logger.debug basesystem.inspect
     
     respond_to do |format|
      format.xml { render  :xml => basesystem.to_xml( :dasherize => false ) }
      format.json { render :json => basesystem.to_json( :dasherize => false ) }
     end
   end

   def update
     @basesystem = Basesystem.new params[:basesystem]     
     @basesystem.save
     show
   end

   def create
     update
   end

end
