# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'polkit'

# The destination
dir_config(extension_name)

$CFLAGS +=  " " + `pkg-config polkit-dbus --cflags`

$LDFLAGS +=  " " + `pkg-config polkit-dbus --libs`
             
# Do the work
create_makefile(extension_name)
