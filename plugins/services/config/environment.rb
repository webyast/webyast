# Load the rails application
require File.expand_path('../application', __FILE__)
#needed for generating mo files...
FastGettext.add_text_domain 'webyast-services', :path => 'locale'
FastGettext.default_text_domain = 'webyast-services'
# Initialize the rails application
Services::Application.initialize!

