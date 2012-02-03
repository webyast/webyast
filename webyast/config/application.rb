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

    # for a slighly faster asset compilation
    # (see http://guides.rubyonrails.org/asset_pipeline.html)
    config.assets.initialize_on_precompile = false

    config.to_prepare do
      Devise::SessionsController.layout "application"
    end
    # remove quiet_assets initializer when this works
    # issue #2639
    #config.assets.logger = nil
  end
end
