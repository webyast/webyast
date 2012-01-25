# Load the rails application
require File.expand_path('../application', __FILE__)
#needed for generating mo files...
FastGettext.add_text_domain 'webyast-users', :path => 'locale'
FastGettext.default_text_domain = 'webyast-users'
# Initialize the rails application
Users::Application.initialize!

