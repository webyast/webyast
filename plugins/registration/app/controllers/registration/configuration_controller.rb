# = Registration::Configuration controller
# Provides access to the configuration of the registration system

class Registration::ConfigurationController < ApplicationController

  before_filter :login_required

  def update
    permission_check("org.opensuse.yast.modules.ysr.setregistrationconfig")

    #request.env.each do |k,v |  puts "==#{k}==  =>  ==#{v.inspect}==" end

    if request.env["rack.input"].size>0
      req = Hash.from_xml request.env["rack.input"].read
    else
      req = Hash.new
    end

    newurl = nil
    newca  = nil

    # read registration server url
    if req['registrationconfig'] &&
       req['registrationconfig']['server'] &&
       req['registrationconfig']['server']['url']
       newurl = req['registrationconfig']['server']['url'].strip
    end

    # read ca certificate file
    if req['registrationconfig'] &&
       req['registrationconfig']['certificate'] &&
       req['registrationconfig']['certificate']['data']
       newca = req['registrationconfig']['certificate']['data'].strip + "\n"

    end

    @register = Register.new({})
    @register.registrationserver = newurl if newurl
    @register.certificate = newca if newca
    @register.save
    render :show
  end

  def show
    permission_check("org.opensuse.yast.modules.ysr.getregistrationconfig")
    # do not run registration, only get the config
    @register = Register.new({})
  end

  def index
    # same as show
    show
  end

end
