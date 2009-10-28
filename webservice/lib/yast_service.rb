require 'exceptions'

class YastService
    require "dbus"

    # cache the importer object, avoid recreation in every Import call
    @@importer = nil

    # cache for imported namespaces, avoid importing an Yast name space
    # and introspecting the DBus object in every call
    # key: name space name, value: DBus object
    @@imported = {}

    # call a Yast function using DBus service
    def YastService.Call(function, *arguments)

	# connect to the system bus
	system_bus = DBus::SystemBus.instance

	# get the Yast namespace service
	yast = system_bus.service('org.opensuse.YaST.modules')

	# parse the function name
	parts = function.split('::')

	# get the last item (the function name)
	fce = parts.pop
	# format the namespace object name
	object = parts.join('/')
	namespace = parts.join('::')

	# has been the namespace already imported?
	if @@imported.has_key?(namespace)
	    dbusobj = @@imported[namespace]
	else
	    # lazy initialization of the importer object
	    if @@importer.nil?
		@@importer = yast.object('/org/opensuse/YaST/modules')
		@@importer.introspect
		@@importer.default_iface = 'org.opensuse.YaST.modules.ModuleManager'
	    end

	    # import the module
	    imported = @@importer.Import(namespace)

	    if imported
		dbusobj = yast.object('/org/opensuse/YaST/modules/' + object)
		dbusobj.introspect
		dbusobj.default_iface = 'org.opensuse.YaST.Values'

		@@imported[namespace] = dbusobj
	     end
	end

	return dbusobj.send(fce, *arguments)[0]


    # handle DBus and PolicyKit errors
    rescue DBus::Error => dbe

	# handle org.freedesktop.PolicyKit.Error.NotAuthorized DBus Error
	if dbe.dbus_message.error_name == 'org.freedesktop.PolicyKit.Error.NotAuthorized' && dbe.dbus_message.params.size == 1
	    parms = dbe.dbus_message.params[0].split(' ')

            # throw a PolicyKit exception instead of the DBus exception
            raise NoPermissionException.new(parms[0], ENV['USER'])
	end

	# rethrow other DBus Errors
	raise dbe

    # handle generic errors (e.g. non existing yast function)
    rescue Exception => e

	# rethow generic exceptions
	raise e
    end
end

