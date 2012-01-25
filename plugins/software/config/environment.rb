# Load the rails application
require File.expand_path('../application', __FILE__)
#needed for generating mo files...
FastGettext.add_text_domain 'webyast-software', :path => 'locale'
FastGettext.default_text_domain = 'webyast-software'
# Initialize the rails application
Software::Application.initialize!

