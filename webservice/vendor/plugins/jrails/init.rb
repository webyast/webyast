# Source: jrails
# uncomment to use jQuery.noConflict()
#ActionView::Helpers::PrototypeHelper::JQUERY_VAR = 'jQuery'

ActionView::Helpers::AssetTagHelper::JAVASCRIPT_DEFAULT_SOURCES = ['jrails']
ActionView::Helpers::AssetTagHelper::reset_javascript_include_default
require 'jrails'
