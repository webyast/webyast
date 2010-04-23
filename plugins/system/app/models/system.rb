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


require 'dbus'
require 'singleton'


class System
    attr_reader :actions

    include Singleton

    def initialize
	@actions = {:reboot => {:active => false}, :shutdown => {:active => false} }
    end

    def reboot
	if hal_power_management(:reboot)
	    @actions[:reboot][:active] = true
	end
    end

    def shutdown
	if hal_power_management(:shutdown)
	    @actions[:shutdown][:active] = true
	end
    end


# private methods
    private

    def hal_power_management(action, params = {})

	return false unless action == :reboot or action == :shutdown

	begin
	    # connect to the system bus
            # Make a fresh connection, to be able to reboot
            # after DBus is restarted, bnc#582759
	    system_bus = DBus::SystemBus.send :new

	    # get the HAL service
	    hal_service = system_bus.service('org.freedesktop.Hal')

	    computer = hal_service.object('/org/freedesktop/Hal/devices/computer')
	    computer.introspect
	    computer.default_iface = 'org.freedesktop.Hal.Device.SystemPowerManagement'

	    case action

		when :reboot
		    if ENV['RAILS_ENV'] == 'production'
			Rails.logger.info 'Rebooting the computer...'
			return computer.Reboot.zero?
		    else
			Rails.logger.warn "Skipping reboot in #{ENV['RAILS_ENV']} mode"
			return true
		    end
		when :shutdown
		    if ENV['RAILS_ENV'] == 'production'
			Rails.logger.info 'Shutting down the computer...'
			return computer.Shutdown.zero?
		    else
			Rails.logger.warn "Skipping shutdown in #{ENV['RAILS_ENV']} mode"
			return true
		    end
		else
		    Rails.logger.error "Unsupported HAL command: #{action}"
	    end

	# handle DBus errors
	rescue DBus::Error => dbe
	    Rails.logger.error "DBus error: #{dbe.dbus_message.error_name}"
	    return false
	# handle generic errors
	rescue Exception => e
	    Rails.logger.error "Caught exception: #{e.message}"
	    return false
	end
    end


end
