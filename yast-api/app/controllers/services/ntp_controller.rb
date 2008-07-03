require 'parsers/ntp/ntp_conf'

class Services::NtpController < ApplicationController
  def create
  end
  def delete
  end
  def show
  end

  def config
    @config = Parsers::Ntp::NtpConf.new
    @config.parse( '/etc/ntp.conf' )
    respond_to do |format|
      format.xml do
        render :xml => @config
      end
      format.json do
        render :json => @config
      end
      format.html do
        render :html => @config
      end
    end
  end
end
