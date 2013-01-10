#--
# Copyright (c) 2009 Novell, Inc.
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
# = Interfacescontroller
# Provides access to interface settings for authenticated users.
# Main goal is checking permissions.
class Network::InterfacesController < ApplicationController

  before_filter(:only => [:show, :index]) { |c| c.authorize! :read, Network }
  before_filter(:only => [:create, :update, :destroy]) { |c| c.authorize! :write, Network }

  # Sets interface settings. Requires write permissions for network YaPI.
  def update
    # :interface is specified, :interfaces is sent by the ui :-/
    root = params[:interface] || params[:interfaces]
    if root == nil
      raise InvalidParameters.new :interface => "Missing", :interfaces => "Missing"
    end
    iface = Interface.new(root)
    iface.save!
    show
  end

  # Shows interface settings. Requires read permission for network YaPI.
  def show
    # RORSCAN_INL: Is not a Information Exposure cause all data can be read
    iface = Interface.find(params[:id])

    Rails.logger.info "Found interface: #{iface.inspect}"

    head :not_found and return if iface.nil?

    respond_to do |format|
      format.xml { render :xml => iface.to_xml( :root => "interface", :dasherize => false ) }
      format.json { render :json => iface.to_json }
    end
  end

  def index
   ifaces_a = Interface.find(:all).values
   respond_to do |format|
     format.xml { render :xml => ifaces_a.to_xml( :root => "interfaces", :dasherize => false ) }
     format.json { render :json => ifaces_a.to_json }
   end
  end

  def create
    options = params[:interface] || {}

    options["bridge_ports"] = options["bridge_ports"].join(' ') || "" if options["bridge_ports"]
    options["bond_slaves"] = options["bond_slaves"].join(' ') if options["bond_slaves"]

    if options["bond_mode"] && options["bond_miimon"]
      bond_option = "#{options["bond_mode"]} #{options["bond_miimon"].gsub(/ /,'')}"
      options["bond_option"] = bond_option
    end

    Rails.logger.info "options: #{options.inspect}"

    ifc = Interface.new(options, "#{options["type"]}#{options["number"]}")
    head 422 and return unless ifc.valid?

    updated = ifc.save
    head :not_found and return unless updated

    respond_to do |format|
      format.xml { render :xml => ifc.to_xml(:dasherize => false) }
      format.json { render :json => ifc.to_json }
    end
  end

  def destroy
    ifc = Interface.find params[:id]
    Rails.logger.info "Found interface: #{ifc.inspect}"
    head :not_found and return if ifc.nil?

    ret = ifc.destroy
    head ret ? :ok : :internal_server_error
  end

end

