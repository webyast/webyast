
# = Systemtime controller
# Provides access to time settings for authentificated users.
# Main goal is checking permissions.
class RolesController < ApplicationController

  before_filter :login_required

  #--------------------------------------------------------------------------------
  #
  # actions
  #
  #--------------------------------------------------------------------------------

  # Sets time settings. Requires write permissions for time YaPI.
  def update
  end

  def create
  end

  # Shows time settings. Requires read permission for time YaPI.
  def show
  end

end
