
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
	    system_bus = DBus::SystemBus.instance

	    # get the HAL service
	    hal_service = system_bus.service('org.freedesktop.Hal')

	    computer = hal_service.object('/org/freedesktop/Hal/devices/computer')
	    computer.introspect
	    computer.default_iface = 'org.freedesktop.Hal.Device.SystemPowerManagement'

	    case action

		when :reboot
		    if ENV['RAILS_ENV'] == 'production'
			Rails.logger.debug 'Rebooting the computer...'
			return computer.Reboot == 0
		    else
			Rails.logger.debug "Skipping reboot in #{ENV['RAILS_ENV']} mode"
			return true
		    end
		when :shutdown
		    if ENV['RAILS_ENV'] == 'production'
			Rails.logger.debug 'Shutting down the computer...'
			return computer.Shutdown == 0
		    else
			Rails.logger.debug "Skipping shutdown in #{ENV['RAILS_ENV']} mode"
			return true
		    end
		else
		    Rails.logger.error "Unsupported HAL command: #{action}"
	    end

	# handle DBus errors
	rescue DBus::Error => dbe
	    logger.error "DBus error: #{dbe.dbus_message.error_name}"
	    return false
	# handle generic errors
	rescue Exception => e
	    logger.error "Caught exception: #{e.message}"
	    return false
	end
    end


end
