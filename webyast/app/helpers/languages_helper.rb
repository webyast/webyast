#! /usr/bin/env ruby
# encoding: utf-8

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

module LanguagesHelper

# NOTE: add the respective jquery.ui.datepicker-*.js file when adding a new language here
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

  # convert language locale code to language name
  # (translated to that langugage)
  def language_name lang
    SUPPORTED_LANGUAGES[lang] || SUPPORTED_LANGUAGES[lang.gsub(/_.*$/, '')] || lang
  end

  # load datepicker translations when available
  def date_picker_localization
    if File.file? File.join(Rails.root, "app", "assets", "javascripts", "jquery.ui.datepicker-#{I18n.locale}.js")
      Rails.logger.debug "Datepicker translations found: #{"jquery.ui.datepicker-#{I18n.locale}.js"}"
      javascript_include_tag "jquery.ui.datepicker-#{I18n.locale}.js"
    end
  end
end

