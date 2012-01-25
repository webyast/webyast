# Load the rails application
require File.expand_path('../application', __FILE__)
#needed for generating mo files...
FastGettext.add_text_domain 'webyast-root-user', :path => 'locale'
FastGettext.default_text_domain = 'webyast-root-user'
# Initialize the rails application
Administrator::Application.initialize!

