require File.expand_path('../boot', __FILE__)
require 'rails/all'
require 'fast_gettext'

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
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.assets.enabled = true
    config.assets.version = '1.0'
    config.secret_token = '9d11bfc98abcf9799082d9c34ec94dc1cc926f0f1bf4bea8c440b497d96b14c1f712c8784d0303ee7dd69e382c3e5e4d38d4c56d1b619eae7acaa6516cd733b1'
    config.to_prepare do
      Devise::SessionsController.layout "main" 
    end
    # remove quiet_assets initializer when this works
    # issue #2639
    #config.assets.logger = nil
  end
end

repos = [FastGettext::TranslationRepository.build('webyast-base', :path => 'locale')]
Rails::Engine::Railties.engines.each do |engine|
  if engine.class.to_s.match /^WebYaST::.*Engine$/
    mo_files = Dir.glob(File.join(engine.config.root, "**", "*.mo"))
    if mo_files.size > 0
      locale_path = File.dirname(File.dirname(File.dirname(mo_files.first))) 
      repos << FastGettext::TranslationRepository.build(File.basename(mo_files.first, ".mo"),
                                                        :path=>locale_path)
    end
  end
end

# TODO: GET AVAILABLE LOCALES AUTOMATICALLY !!!!
FastGettext.add_text_domain 'combined', :type=>:chain, :chain=>repos
FastGettext.default_text_domain = 'combined'
FastGettext.default_available_locales = ["ar","cs","de","es","en_US","fr","hu","it","ja","ko","nl","pl","pt_BR","ru","sv","zh_CN","zh_TW"]





