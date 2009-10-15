require 'vendor_setting'

class VendorSettingsController < ApplicationController
  # this controller has to work even if EULA is not accepted. More on this in ApplicationController.
  skip_before_filter :ensure_eulas

  def index
    settings = []
    begin
      settings = VendorSetting.find(:all)
    rescue YaST::ConfigFile::NotFoundError
      render :nothing => true, :status => 404 and return
    rescue Exception => e
      render :nothing => true, :status => 500 and return
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
      render :nothing => true, :status => 404 and return
    rescue Exception => e
      render :nothing => true, :status => 500 and return
    end

    respond_to do |format|
      format.xml { render :xml => setting.to_xml }
      format.json { render :json => setting.value.to_json }
    end
  end
end
