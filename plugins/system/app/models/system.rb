
require 'dbus'
require 'singleton'


class System

    include Singleton

    def initialize
	@reboot = false
	@shutdown = false
    end

    def actions
	return {:reboot => @reboot, :shutdown => @shutdown}
    end

    def reboot
	logger.debug "##### reboot"
#	if hal_power_management(:reboot)
#	    @reboot = true
#	end
    end

    def shutdown
	logger.debug "##### shutdown"
#	if hal_power_management(:shutdown)
#	    @shutdown = true
#	end
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
		    logger.debug 'Rebooting the computer...'
		    return computer.Reboot == 0
		when :shutdown
		    logger.debug 'Shutting down the computer...'
		    return computer.Shutdown == 0
		else
		    logger.error "Unsupported HAL command: #{action}"
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
