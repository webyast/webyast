# Load the rails application
require File.expand_path('../application', __FILE__)
#needed for generating mo files...
FastGettext.add_text_domain 'webyast-firewall', :path => 'locale'
FastGettext.default_text_domain = 'webyast-firewall'
# Initialize the rails application
Firewall::Application.initialize!

