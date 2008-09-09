class SysconfigsController < ApplicationController
  require 'sysconfig'
  def index
    @sysconfigs = Array.new
    Dir.foreach( '/etc/sysconfig' ) do |d|
      next if not File.file?( '/etc/sysconfig/'+d )
      sysconfig = Sysconfig.new
      sysconfig.name = d
      @sysconfigs << sysconfig
    end
    respond_to do |format|
      format.xml do
        render :xml => @sysconfigs.to_xml
      end
      format.json do
        render :json => @sysconfigs.to_json
      end
      format.html do
        #render :html => @sysconfigs.to_html
        render
      end
    end
  end
end
