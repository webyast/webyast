# = RegistrationConfiguration controller
# Provides access to the configuration of the registration system
#class Registration::ConfigurationController < ApplicationController
class ConfigurationController < ApplicationController

  before_filter :login_required

  def update
    #request.env.each do |k,v |  puts "==#{k}==  =>  ==#{v.inspect}==" end

    if request.env["rack.input"].size>0
      req = Hash.from_xml request.env["rack.input"].read
    else
      req = Hash.new
    end

    newurl = ''
    newca  = ''

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

    @registration = Registration.new( { } )
    @registration.set_config newurl, newca
    render :show
  end

  def show
    # do not run registration, only get the config
    @registration = Registration.new( { } )
    @registration.get_config
  end

  def index
    # same as show
    show
  end

end
