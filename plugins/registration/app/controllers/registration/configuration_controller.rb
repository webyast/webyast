#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

# = Registration::Configuration controller
# Provides access to the configuration of the registration system

class Registration::ConfigurationController < ApplicationController

  before_filter :login_required

  def update
    permission_check("org.opensuse.yast.modules.ysr.setregistrationconfig")

    newurl = nil
    newca  = nil

    # read registration server url
    if params['registrationconfig'] &&
       params['registrationconfig']['server'] &&
       params['registrationconfig']['server']['url']
       newurl = params['registrationconfig']['server']['url'].strip
    end

    # read ca certificate file
    if params['registrationconfig'] &&
       params['registrationconfig']['certificate'] &&
       params['registrationconfig']['certificate']['data']
       newca = params['registrationconfig']['certificate']['data'].strip + "\n"
    end

    @register = Register.new
    @register.registrationserver = newurl if newurl
    @register.certificate = newca if newca
    @register.save || raise("Error: Could not save the new registration configuration.")
    render :show
  end

  def show
    permission_check("org.opensuse.yast.modules.ysr.getregistrationconfig")
    # do not run registration, only get the config
    @register = Register.new
  end

  def index
    # same as show
    show
  end

end
