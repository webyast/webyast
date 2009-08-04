# = Language controller
# Provides access to language settings for authentificated users.
# Main goal is checking permissions.
class LanguageController < ApplicationController

  before_filter :login_required
  #--------------------------------------------------------------------------------
  #
  # actions
  #
  #--------------------------------------------------------------------------------

  # Actualizes language settings. Requires write permissions for language YaPI.
  def update    
    if params.has_key?(:language)
      unless permission_check("org.opensuse.yast.modules.yapi.language.write")
        render ErrorResult.error(403, 1, "no permission") and return
      end
      @language = Language.new
      @language.language = params[:language][:current]
      @language.utf8 = params[:language][:utf8]
      @language.rootlocale = params[:language][:rootlocale]
      @language.save
       
    else
      logger.warn("No argument to update")
      render ErrorResult.error(404, 2, "format or internal error") and return
    end
    render :show
  end

  # See update
  def create
    update
  end

  # Shows language settings. Requires read permission for language YaPI.
  def show
    unless permission_check("org.opensuse.yast.modules.yapi.language.read")
      render ErrorResult.error(403, 1, "no permissions") and return
    end
    @language = Language.new
    @language.find

  end

end
