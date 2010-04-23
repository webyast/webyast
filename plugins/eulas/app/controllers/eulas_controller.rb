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

# = Eula controller
# Serves licences and handles notices about acceptations.
# User does not need any permissions
class EulasController < ApplicationController

  before_filter :login_required
  before_filter :ensure_license, :only => [:show, :update]
  
  #--------------------------------------------------------------------------------
  #
  # actions
  #
  #--------------------------------------------------------------------------------

  # Renders a list of all available licences. Some (but not all) licence attributes
  # are shown, especially whether the license was already accepted or not.
  def index
    @licenses = License.find_all
    respond_to do |format|
      format.xml { render :xml => @licenses.to_xml }
      format.json{ render :json=> @licenses.to_json}
    end
  end

  # Render detailed info about a particular licence. Not all translations are 
  # rendered, only the selected one or english by default.
  def show
    @license.load_text params[:lang] unless params[:lang].nil?
    logger.debug @license.inspect
    respond_to do |format|
      format.xml { render :xml => @license.to_xml }
      format.json{ render :json=> @license.to_json}
    end
  end
  
  # Save updated license data. The only changeable attribute is "accepted"
  def update
    permission_check :'org.opensuse.yast.modules.eulas.accept'
    raise InvalidParameters.new({:id => 'MISSING'}) if params[:id].nil?
    raise InvalidParameters.new({:eulas_accepted => 'INVALID'}) unless [true,false,"true","false"].include? params[:eulas][:accepted]
    @license = License.find params[:id]
    render ErrorResult.error(404, 1, "License not found") and return if @license.nil?
    @license.accepted = ([true,"true"].include? params[:eulas][:accepted]) ? true : false
    @license.save
    respond_to do |format|
      format.xml { render :xml => @license.to_xml }
      format.json{ render :json=> @license.to_json}
    end
  end

  private

  def ensure_license
    raise InvalidParameters.new({:id => 'MISSING'}) if params[:id].nil?
    @id      = params[:id].to_i
    @license = License.find @id
    render ErrorResult.error(404, 1, "License not found") and return if @license.nil?
  end

end
