# encoding: utf-8
module LanguagesHelper

SUPPORTED_LANGUAGES = {
  "ar" => "العربية",
  "cs" => "Čeština",
  "de" => "Deutsch",
  "es" => "Español",
  "en_US" => "English (US)",
  "fr" => "Français",
  "hu"=> "Magyar",
  "it" => "Italiano",
  "ja" => "日本語",
  "ko" => "한글 ",
  "nl" => "Nederlands",
  "pl" => "Polski",
  "pt_BR" => "Português brasileiro",
  "ru" => "Русский",
  "sv" => "Svenska",
  "zh_CN" => "简体中文",
  "zh_TW" => "繁體中文"
}

  def supported_languages
    return SUPPORTED_LANGUAGES
  end
end

