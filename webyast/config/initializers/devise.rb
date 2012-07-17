Devise.setup do |config|
  require 'devise/orm/active_record'
  config.use_salt_as_remember_token = false
  config.authentication_keys = [:username]
  config.timeout_in = 120.minutes

  # enable HTTP Basic authentication
  config.http_authenticatable = true
  config.http_authentication_realm = "WebYaST"
end
