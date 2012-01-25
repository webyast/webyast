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

require 'error_result'

class SystemController < ApplicationController

    def show
   	@actions = System.instance.actions

	respond_to do |format|
	    format.xml  { render :xml => @actions.to_xml(:root => :actions), :location => "none" }
	    format.json { render :json => @actions.to_json, :location => "none" }
	end
    end
   
    def update
	
      @system = System.instance

      do_reboot = false
      do_shutdown = false

      case params[:id].to_sym
	when :reboot
          authorize! :reboot, System

          if @system.actions[:reboot][:active] == false
            do_reboot = true
          end
        when :shutdown
          authorize! :shutdown, System

	  if @system.actions[:shutdown][:active] == false
	    do_shutdown = true
	  end
	else
	  render ErrorResult.error(404, 2, "internal error - unknown action requested") and return
      end

      if do_reboot then @system.reboot end
      if do_shutdown then @system.shutdown end

      show
    end

    # See update
    def create
	update
    end

    def reboot
        authorize! :reboot, System
	@sys = System.instance
	if request.put?
          if !@sys.nil? and @sys.reboot
            flash[:message] = _("Rebooting the machine...")
            # logout from the service, reboot is in progress
            redirect_to(logout_path) and return
          else
            flash[:error] = _("Cannot reboot the machine!")
          end
	else
	    flash[:error] = 'Reboot request is accepted only via PUT method!'
	end

	redirect_to :controller => :controlpanel, :action => :index
    end

    def shutdown
      authorize! :shutdown, System
      @sys = System.instance
      if request.put?
        if !@sys.nil? and @sys.shutdown
          flash[:message] = _("Shuting down the machine...")
          # logout from the service, shut down is in progress
          redirect_to(logout_path) and return
        else
          flash[:error] = _("Cannot shutdown the machine!")
        end
      else
          flash[:error] = 'Shutdown request is accepted only via PUT method!'
      end

      redirect_to :controller => :controlpanel, :action => :index
    end

end
