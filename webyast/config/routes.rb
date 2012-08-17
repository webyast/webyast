#--
# Webyast framework
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

Webyast::Application.routes.draw do

  devise_for :accounts,  :controllers => { :sessions => "sessions" }

  resources :notifier, :only => :index do
    get 'status', :on => :collection
  end

  resources :onlinehelp, :only => :show
  resource :vendor_settings, :only => :show
  resources :restdoc, :only => [:index, :show]
  resources :resources, :only => [:index, :show], :constraints => { :id => /[-\w]+/ }

  #mounting each plugin
  if defined? WebYaST
    webyast_module = Object.const_get("WebYaST")
    webyast_plugins = webyast_module.constants
    webyast_plugins.each do |plugin|
      mount webyast_module.const_get(plugin) => '/'
    end
  end

  root :to => 'controlpanel#index'

  match '/:controller(/:action(/:id))'

  # for custom 404 error handling, workaround for a Rails bug
  # see https://rails.lighthouseapp.com/projects/8994/tickets/4444-can-no-longer-rescue_from-actioncontrollerroutingerror
  match '*a', :to => 'errors#routing'
end
