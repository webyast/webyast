# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'polKit'

# The destination
dir_config(extension_name)

$CFLAGS << " -I /usr/include/PolicyKit -I /usr/include/dbus-1.0 -I /usr/lib/dbus-1.0/include/"

$LDFLAGS << " -L/lib -lpolkit-dbus -lpolkit -ldbus-1 "
             
# Do the work
create_makefile(extension_name)
