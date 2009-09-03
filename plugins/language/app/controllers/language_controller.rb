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
      yapi_perm_check "language.write"

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
    yapi_perm_check "language.read"

    @language = Language.find
  end

end
