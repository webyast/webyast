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

include ApplicationHelper
require 'firewall'

class FirewallController < ApplicationController

  CGI_PREFIX="firewall"
  NEEDED_SERVICES = ["service:webyast"]
  
  private

  def checkbox_true?(name)
    params[name] == "true"
  end

  public 
    def index
      authorize! :read, Firewall
    
      @firewall = Firewall.find
      @firewall.fw_services.sort! {|x,y| x["name"].downcase <=> y["name"].downcase}
      
      Rails.logger.info @firewall.inspect

      if request.format.xml?
          render :xml => @firewall.to_xml(:dasherize => false) and return
      end
      if request.format.json?
          render :json => @firewall.to_json and return
      end

      @firewall.fw_services.each do |service|
        service["css_class"] = CGI_PREFIX+"-"+service["id"].gsub(/^service:/,"service-")
        service["name"] = service["id"].gsub(/^service:/,"")
        service["input_name"] = CGI_PREFIX+"_"+service["id"]
      end

      @needed_services = @firewall.fw_services.find_all{|s| NEEDED_SERVICES.include?(s["id"])}
    end
    

    def show
      authorize! :read, Firewall

      respond_to do |format|
        format.xml  { render  :xml => Firewall.find.to_xml( :dasherize => false ) }
        format.html { index }
        format.json { render :json => Firewall.find.to_json( :dasherize => false ) }
      end
    end
    
    def update
      authorize! :write, Firewall
      firewall = Firewall.find 
      root = params["firewall"]
      
      if root == nil || root == {}
        raise InvalidParameters.new :firewall => "Missing"
      end
        
      if request.format.html?
        Rails.logger.error "HTML"
        
        firewall.use_firewall = checkbox_true? "use_firewall"

        firewall.fw_services.each do |service|
          service["allowed"] = checkbox_true?(CGI_PREFIX+"_" + service["id"])
        end
        
        firewall.save
        flash[:notice] = _('Firewall settings have been written.')
        redirect_success
        
      else
        Rails.logger.error "XML"
        
        firewall = Firewall.new(root)
        firewall.save
        show
      end
    end

    # See update
    def create
      update
    end
end
