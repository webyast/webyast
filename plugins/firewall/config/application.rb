require 'rails/all'
require 'fast_gettext'

if defined?(Bundler)
  Bundler.require *Rails.groups(:assets) if defined?(Bundler)
end

module Firewall
  class Application < Rails::Application
  end
end
