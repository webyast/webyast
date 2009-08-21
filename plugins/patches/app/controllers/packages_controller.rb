require 'singleton'

class PackagesController < ApplicationController

   before_filter :login_required

  private

  def check_read_permissions
    unless permission_check( "org.opensuse.yast.system.patches.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end
  end

  public

  # GET /packages
  # GET /packages.xml
  def index
    # note: permission check was performed in :before_filter
    @installed_packages = Package.find()
    if @installed_packages == -1
      logger.error "Package Module: DBUS Resource is not available."
      render ErrorResult.error(423, 1, "DBUS Resource is not available.") and return
    end
  end
end
