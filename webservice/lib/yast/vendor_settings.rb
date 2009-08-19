
require 'yast/config_file'

module YaST

  # Vendor custom configuration of
  # the host, located in /etc/YaST2/vendor.yml
  class VendorSettings

    def initialize
      @config = ConfigFile.new(:vendor)
    end
    
    # eula that will be displayed
    def eula
    end
    
  end
    
end
