# = Paths
# the module provides constant for yastws package. Paths identifies places
# where is all data, that are not in yastws server place, go.
module Paths
  ROOT="/" #it is not true on windows, change during packaging

# Place where store files which storing states.
  VAR=File.join(ROOT,"var","lib","yastws")

# Place for static data that is not rendered and should not be available web server. Read-Only.
  DATAS=File.join(ROOT,"usr","share","yastws")

# Configuration place where is stored configuration place. Read-only.
  CONFIG=File.join(ROOT,"etc","webyast")

# Logfile for the registration - default is the YaST default: /root/.suse_register.log
  REGISTRATION_LOG=File.join(ROOT, "root", ".suse_register.log")
end
