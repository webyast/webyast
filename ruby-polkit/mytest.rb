# Load in the extension (on OS X this loads ./MyTest/mytest.bundle - unsure about Linux, possibly polKit.so)
require 'polKit'

# Polkit is now a module, so we need to include it
include PolKit

# Call and print the result from the polkit_check method
puts PolKit::polkit_check( "opensuse.yast.scr.read.sysconfig.clock.timezone", "schubi")

