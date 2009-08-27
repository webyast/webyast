require 'vendor_setting'

class VendorSettingsController < ApplicationController

  def index
    settings = VendorSetting.find(:all)
    respond_to do |format|
      format.xml { render :xml => settings.to_xml }
      format.json { render :json => VendorSetting }
    end
  end

  def show
    setting = VendorSetting.find(params[:id])
    respond_to do |format|
      format.xml { render :xml => settings.to_xml }
      format.json { render :json => setting.value.to_json }
    end
  end
end
