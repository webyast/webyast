require 'vendor_setting'

class VendorSettingsController < ApplicationController

  def index
    settings = []
    begin
      settings = VendorSetting.find(:all)
    rescue YaST::ConfigFile::NotFoundError
      logger.info "vendor settings not found"
      render :nothing => true, :status => 404 and return
    end
    respond_to do |format|
      format.xml { render :xml => settings.to_xml }
      format.json { render :json => VendorSetting }
    end
  end

  def show
    setting = nil
    begin
      setting = VendorSetting.find(params[:id])
      if setting.nil?
        render :nothing => true, :status => 404 and return
      end
    rescue YaST::ConfigFile::NotFoundError
      logger.info "vendor settings not found"
      render :nothing => true, :status => 404 and return
    end

    respond_to do |format|
      format.xml { render :xml => setting.to_xml }
      format.json { render :json => setting.value.to_json }
    end
  end
end
