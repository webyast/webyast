# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'polkit1'

# The destination
dir_config(extension_name)

$CFLAGS +=  " " + `pkg-config polkit-gobject-1 --cflags`

$LDFLAGS +=  " " + `pkg-config polkit-gobject-1 --libs`
             
# Do the work
create_makefile(extension_name)
