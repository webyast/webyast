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
    yapi_perm_check "language.write"
    if params.has_key?(:language)

      @language = Language.new params[:language]
      @language.save
    else
      logger.warn("No argument to update")
      raise InvalidParameters.new :language => "Missing"
    end
    show
  end

  # See update
  def create
    update
  end

  # Shows language settings. Requires read permission for language YaPI.
  def show
    yapi_perm_check "language.read"

    @language = Language.find

    respond_to do |format|
      format.html { render :show  }
      format.xml { render  :xml => systemtime.to_xml( :dasherize => false ) }
      format.json { render :json => systemtime.to_json( :dasherize => false ) }
    end
  end

end
