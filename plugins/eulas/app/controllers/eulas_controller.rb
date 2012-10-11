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

require 'enumerator'

class EulasController < ApplicationController
  before_filter :ensure_license, :only => [:show, :update]
  before_filter :ensure_eula_count, :only => [:show, :index, :update]
  before_filter :ensure_id, :only => [:show, :update]

private
    def ensure_eula_count
      if session[:eula_count].nil?
        licenses = License.find_all
        Rails.logger.debug "#{licenses.length} licences found"
        session[:eula_count] = licenses.length
      end
      @eula_count = session[:eula_count]
    end

    def ensure_id
      redirect_to :action => :show, :id => 1 and return if params[:id].nil? # RORSCAN_ITL
      @eula_id   = [1,params[:id].to_i].max
    end

    def next_in_range(range, current)
      [current+1, range.max].min
    end

    def prev_in_range(range, current)
      [current-1, range.min].max
    end

  public
    def index
      if request.format.html?
        if session[:eula_count] == 0
          Rails.logger.debug "No licences found"
          render :no_licenses
        else
          Rails.logger.debug "Show first licence"
          redirect_to :action => :show, :id => 1
        end
      else
        @licenses = License.find_all
        respond_to do |format|
          format.xml { render :xml => @licenses.to_xml }
          format.json{ render :json=> @licenses.to_json}
        end
      end
    end

    def show
      if request.format.html?
        @prev_id = prev_in_range( (1..@eula_count), @eula_id)
        @last_eula = @eula_id == @eula_count
        @first_eula= @eula_id == 1
        basesystem = Basesystem.new.load_from_session(session)
        @first_basesystem_step = basesystem ? basesystem.first_step? : false
        @basesystem_completed = basesystem ? basesystem.completed? : true
        
        @eula = License.find @eula_id
        @eula.load_text FastGettext.locale unless FastGettext.locale.blank?
      else
        Rails.logger.error "TO XML"
        #OLD: @license.load_text params[:lang] unless params[:lang].nil?      
        # RORSCAN_INL: No Information Exposure cause everyone can read licence text
        @license = License.find params[:id]
        @license.load_text params[:lang] unless params[:lang].nil?
       
        respond_to do |format|
          format.xml { render :xml => @license.to_xml }
          format.json{ render :json=> @license.to_json}
        end
       end
    end

    def update
      authorize! :accept, License
      if request.format.html?
        #@eula = License.find(@eula_id, FastGettext.locale)
        @eula = License.find @eula_id
        @eula.load_text FastGettext.locale unless FastGettext.locale.blank?
        
        @eula.text = ""
        @eula.available_langs = []
        @eula.id = @eula_id
        
        accepted = params[:eula] && params[:eula][:accepted] == "true"
        
        if accepted
          @eula.accepted = accepted
          @eula.save # do not save again if there is no change
          if @eula_count == @eula_id
            redirect_success
            return
          end
          next_id = next_in_range( (1..@eula_count), @eula_id)
        else
          flash[:error] = n_("You need to accept the licence before using this product.",
            "You need to accept all licences before using this product.", @eula_count)
          next_id = @eula_id
        end
        redirect_to :action => :show, :id => next_id
      
      else
         raise InvalidParameters.new({:id => 'MISSING'}) if params[:id].nil? # RORSCAN_ITL
        raise InvalidParameters.new({:eulas_accepted => 'INVALID'}) unless [true,false,"true","false"].include? params[:eulas][:accepted] # RORSCAN_ITL
        # RORSCAN_INL: No Information Exposure cause everyone can read licence text      
        @license = License.find params[:id]
        @license.load_text params[:lang] unless params[:lang].nil?
        
        render ErrorResult.error(404, 1, "License not found") and return if @license.nil?
        @license.accepted = ([true,"true"].include? params[:eulas][:accepted]) ? true : false
        @license.save
  
        respond_to do |format|
          format.xml { render :xml => @license.to_xml }
          format.json{ render :json=> @license.to_json}
        end
      
      end
    end

  private

  def ensure_license
    raise InvalidParameters.new({:id => 'MISSING'}) if params[:id].nil? # RORSCAN_ITL
    @id = params[:id].to_i
    @license = License.find @id
    @license.load_text params[:lang] unless params[:lang].nil?
    render ErrorResult.error(404, 1, "License not found") and return if @license.nil?
  end

end
