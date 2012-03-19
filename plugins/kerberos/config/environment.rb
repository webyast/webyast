# Load the rails application
require File.expand_path('../application', __FILE__)
#needed for generating mo files...
FastGettext.add_text_domain 'webyast-kerberos', :path => 'locale'
FastGettext.default_text_domain = 'webyast-kerberos'
# Initialize the rails application
Kerberos::Application.initialize!

