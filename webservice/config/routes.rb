#--
# Webyast Webservice framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

# route sessions statically, it is a singleton controller
ActionController::Routing::Routes.draw do |map|
  map.resource :session
  
  #resources is not restful as it allows only read only access. It is more likely inspection
  map.connect 'resources/:id.:format',  :controller => 'resources', :action => 'show', :requirements => { :id => /[-\w]+/ }
  map.all_resources 'resources.:format',  :controller => 'resources', :action => 'index'
  map.root :all_resources
  map.resource :permissions
  map.resource :vendor_settings
  
  # login uses POST for both
  map.login "/login.:format", :controller => 'sessions', :action => 'create'
  map.logout "/logout.:format", :controller => 'sessions', :action => 'destroy'

  map.restdoc "/restdoc.:format", :controller => 'restdoc', :action => 'index'

  map.resources :logs
  
  #FIXME: this is a workaround only
  map.notifier "/notifiers/status.:format",  :controller => "notifier", :action => "status"
end
