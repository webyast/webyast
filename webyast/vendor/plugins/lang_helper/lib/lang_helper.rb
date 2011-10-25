# coding: utf-8
# gettext_plugin.rb - a sample script for Ruby on Rails
#
# Copyright (C) 2005-2007 Masao Mutoh
#
# This file is distributed under the same license as Ruby-GetText-Package.

require 'gettext'

module LangHelper
  include GetText

  bindtextdomain("lang_helper", :path => File.join(Rails.root, "vendor/plugins/lang_helper/locale"))

  LANGUAGES = { 'af' => 'Afrikaans', 'ar' => 'العربية', 'be' => 'Беларуская', 'bg' => 'Български', 'bn' => 'বাংলা',
    'bs' => 'Bosanski', 'ca' => 'Català', 'cs' => 'Čeština', 'cy' => 'Cymraeg', 'da' => 'Dansk',
    'de' => 'Deutsch', 'el' => 'Ελληνικά ', 'en' => 'English', 'en_GB' => 'English (UK)', 'en_US' => 'English (US)',
    'es' => 'Español', 'et' => 'Eesti', 'fi' => 'Suomi', 'fr' => 'Français', 'gl' => 'Galego',
    'gu' => 'ગુજરાતી', 'he' => 'עברית', 'hi' => 'हिन्दी', 'hr' => 'Hrvatski', 'hu' => 'Magyar',
    'id' => 'Bahasa Indonesia', 'it' => 'Italiano', 'ja' => '日本語', 'ka' => 'ქართული',
    'km' => 'ខ្មែរ', 'ko' => '한글 ', 'lo' => 'ພາສາລາວ', 'lt' => 'Lietuvių', 'mk' => 'Македонски', 'mr' => 'मराठी',
    'nb' => 'Norsk', 'nl' => 'Nederlands', 'pa' => 'ਪੰਜਾਬੀ', 'pl' => 'Polski',
    'pt_BR' => 'Português brasileiro', 'pt' => 'Português', 'ro' => 'Română', 'ru' => 'Русский ',
    'si' => 'සිංහල', 'sk' => 'Slovenčina', 'sl' => 'Slovenščina', 'sr' => 'Srpski',
    'sv' => 'Svenska', 'ta' => 'தமிழ்', 'tg' => 'тоҷикӣ', 'th' => 'ภาษาไทย', 'tr' => 'Türkçe',
    'uk' => 'Українська', 'vi' => 'Tiếng Việt', 'wa' => 'Walon', 'xh' => 'isiXhosa',
    'zh_CN' => '简体中文', 'zh_TW' => '繁體中文', 'zu' => 'isiZulu'}


  def current_locale_image
    return "/images/flags/#{locale.language}.png"
  end

  def current_locale
    ret = locale.language
    Rails.logger.info("detected locale #{ret}")
    #find locale from existing one, translate if locale came from browser to current one, fallback to american english
    default = lambda{return "en_US"} #detect require something which response to call
    ret = supported_languages.detect(default) { |k| ret.tr('-','_').downcase == k.downcase ? k : nil}
    Rails.logger.info("returned locale #{ret}")
    return ret
  end

  def language_name(code)
    language = LANGUAGES[code]
    if language.nil?
      Rails.logger.warn "Missing text for language code #{current_locale}"
      language = code
    end
    language
  end

  def language_code(name)
    language = LANGUAGES.index(name)
    language.strip.split('_')[1]? language.split('_')[1] : language
  end

  def current_locale_name
    # check full locale at first (language + country)
    if LANGUAGES.has_key?(locale.to_s)
      return language_name locale.to_s
    end

    # use only language code
    language_name current_locale
  end

  def show_language
    langs = supported_languages.sort
    ret = "<h4>" + _("Select locale") + "</h4>"
    langs.each_with_index do |lang, i|
      ret << link_to( language_name(lang),
                     :action => "cookie_locale", :id => lang)
      ret << "<br/>"
    end
    ret
  end

  def cookie_locale
    cookies["lang"] = params["id"]
    set_locale params["id"]
#    flash[:notice] = _('Cookie &quot;lang&quot; is set: %s') % params["id"]
    redirect_to :back
  end

    #do not use this constant (only internal), use supported_languages method
    SUPPORTED_LANGUAGE= [
     "ar","cs","de","es","en_US","fr","hu","it","ja","ko",
     "nl","pl","pt_BR","ru","sv","zh_CN","zh_TW"
    ]
  def supported_languages
    #TODO read from file if vendor want create own translations
    #list is same as SLE11SP1 supported
    return SUPPORTED_LANGUAGE
  end
end

