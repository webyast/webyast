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

require File.expand_path('../boot', __FILE__)
require 'rails/all'
#require 'fast_gettext'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  #Bundler.require(*Rails.groups(:assets => %w(development test)))
  Bundler.require *Rails.groups(:assets) if defined?(Bundler)
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end



module Webyast
  class Application < Rails::Application
    require 'plugin_job'
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/lib/validators #{config.root}/lib/common)
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.assets.enabled = true
    config.assets.version = '1.0'
    config.secret_token = '9d11bfc98abcf9799082d9c34ec94dc1cc926f0f1bf4bea8c440b497d96b14c1f712c8784d0303ee7dd69e382c3e5e4d38d4c56d1b619eae7acaa6516cd733b1'

    # precompile all webyast-* assets from plugins
    config.assets.precompile += ['webyast-*', 'webyast-base-*']

    # for a slighly faster asset compilation
    # (see http://guides.rubyonrails.org/asset_pipeline.html)
    config.assets.initialize_on_precompile = false

    # use yui-compressor
    config.assets.js_compressor = :yui

    config.to_prepare do
      Devise::SessionsController.layout "application"
    end
    # remove quiet_assets initializer when this works
    # issue #2639
    #config.assets.logger = nil
  end
end
