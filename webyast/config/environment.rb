# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Webyast::Application.initialize!

GettextI18nRails.translations_are_html_safe = true
Rails.cache.clear 

STDERR.puts "********* Running in production mode" if Rails.env.production?
STDERR.puts "********* Running in development mode" if Rails.env.development?
STDERR.puts "********* Running in test mode" if Rails.env.test?

