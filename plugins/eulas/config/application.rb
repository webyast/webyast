require 'rails/all'
require 'fast_gettext'

if defined?(Bundler)
  Bundler.require *Rails.groups(:assets) if defined?(Bundler)
end

module Eulas
  class Application < Rails::Application
    config.assets.enabled = true
    config.assets.version = '1.0'

    # precompile all webyast-* assets from plugins
    config.assets.precompile += ['webyast-plugin-*']

    # Generate digests for assets URLs.
    config.assets.digest = true
  end
end
