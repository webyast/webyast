
# put 'en_US' as first, the first item is used as a fallback
# when requested locale (via ?locale= URL parameter) is not found
FastGettext.default_available_locales = ["en_US"]

repos = [FastGettext::TranslationRepository.build('webyast-base', :path => 'locale')]
Rails::Engine::Railties.engines.each do |engine|
  if engine.class.to_s.match /^WebYaST::.*Engine$/
    mo_files = Dir.glob(File.join(engine.config.root, "**", "*.mo"))

    mo_files.each do |l|
      if l.match(/\/([^\/]+)\/LC_MESSAGES\/.*\.mo$/) && !FastGettext.default_available_locales.include?($1)
        FastGettext.default_available_locales << $1
      end
    end

    if mo_files.size > 0
      locale_path = File.dirname(File.dirname(File.dirname(mo_files.first)))
      repos << FastGettext::TranslationRepository.build(File.basename(mo_files.first, ".mo"),
                                                        :path=>locale_path)
    end
  end
end

# add also locales from the main application
Dir[File.join(File.dirname(__FILE__), '..', '..', 'locale', "/*/LC_MESSAGES/*.mo")].each do |l|
  if l.match(/\/([^\/]+)\/LC_MESSAGES\/.*\.mo$/) && !FastGettext.default_available_locales.include?($1)
    FastGettext.default_available_locales << $1
  end
end

FastGettext.add_text_domain 'combined', :type=>:chain, :chain=>repos
FastGettext.default_text_domain = 'combined'

# uncomment for debugging - pretend all supported (?) translations available
# FastGettext.default_available_locales = ["en_US","ar","cs","de","es","fr","hu","it","ja","ko","nl","pl","pt_BR","ru","sv","zh_CN","zh_TW"]

Rails.logger.info "Available translations: #{FastGettext.default_available_locales.inspect}"

# enable fallback handling
I18n::Backend::Simple.include(I18n::Backend::Fallbacks)

# set some locale fallbacks needed for ActiveRecord translations
# located in rails_i18n gem (e.g. there is en-US.yml translation)
I18n.fallbacks[:"en_US"] = [:"en-US", :en]
I18n.fallbacks[:"en_GB"] = [:"en-GB", :en]
I18n.fallbacks[:"pt_BR"] = [:"pt-BR", :pt]
I18n.fallbacks[:"zh_CN"] = [:"zh-CN"]
I18n.fallbacks[:"zh_TW"] = [:"zh-TW"]
I18n.fallbacks[:"sv"] = [:"sv-SE"]

# configure default msgmerge parameters (the default contains "--no-location" option
# which removes code lines from the final POT file)
Rails.application.config.gettext_i18n_rails.msgmerge = ["--sort-output", "--no-wrap"]

