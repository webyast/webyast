require File.expand_path('../boot', __FILE__)
require 'rails/all'
require 'fast_gettext'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Webyast
  class Application < Rails::Application
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.assets.enabled = true
    config.assets.version = '1.0'
    config.secret_token = '9d11bfc98abcf9799082d9c34ec94dc1cc926f0f1bf4bea8c440b497d96b14c1f712c8784d0303ee7dd69e382c3e5e4d38d4c56d1b619eae7acaa6516cd733b1'
  end
end

FastGettext.add_text_domain 'webyast-base', :path => 'locale'
FastGettext.default_text_domain = 'webyast-base'
FastGettext.default_available_locales = ['en','de'] # JUST FOR TEST -> !!! IMPORTANT ADD ALL AVAILABLE LANGUAGES !!!

