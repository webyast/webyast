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


class SystemController < ApplicationController

    before_filter :login_required

    # Initialize GetText and Content-Type.
    init_gettext "webyast-reboot"

    def show
   	@actions = System.instance.actions

	respond_to do |format|
	    format.xml  { render :xml => @actions.to_xml(:root => :actions), :location => "none" }
	    format.json { render :json => @actions.to_json, :location => "none" }
	end
    end
   
    def update
	root = params[:system]
	if root == nil || root == {} 
	  render ErrorResult.error(404, 2, "format error - missing actions") and return
	end
	
	@system = System.instance

	do_reboot = false
	do_shutdown = false

	# do the action
	root.each do |k, v|
	    if v.nil? or !v.respond_to?('has_key?') or !v.has_key? 'active'
		render ErrorResult.error(404, 2, "format error - missing requested status") and return
	    end

	    if v['active'] != true and v['active'] != false
		render ErrorResult.error(404, 2, "format error - non-boolean active parameter") and return
	    end

	    # unknown action requested
	    if !@system.actions.has_key? k.to_sym
		render ErrorResult.error(404, 2, "format error - unknown action requested") and return
	    end

	    case k
		when 'reboot'
		    permission_check( 'org.opensuse.yast.system.power-management.reboot')

		    if v['active'] == true and @system.actions[k.to_sym][:active] == false
			do_reboot = true
		    end
		when 'shutdown'
		    permission_check( 'org.opensuse.yast.system.power-management.shutdown')

		    if v['active'] == true and @system.actions[k.to_sym][:active] == false
			do_shutdown = true
		    end
		else
		    render ErrorResult.error(404, 2, "internal error - unknown action requested") and return
	    end
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
        permission_check( 'org.opensuse.yast.system.power-management.reboot')
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
      permission_check( 'org.opensuse.yast.system.power-management.shutdown')
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
