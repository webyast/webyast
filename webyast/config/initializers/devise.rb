Devise.setup do |config|
  require 'devise/orm/active_record'
  config.authentication_keys = [:username]
  config.timeout_in = 120.minutes
  config.token_authentication_key = :auth_token

  # enable HTTP Basic authentication
  config.http_authenticatable = true
  config.http_authentication_realm = "WebYaST"
end


# monkey patch: token authentication timeout for devise
# NOTE: probably not needed in devise-2.x, it seems that the token timeout
#       is supported there natively

module Devise
  module Models
    module TokenAuthenticatable
      module ClassMethods
        def find_for_token_authentication(conditions)
          account = find_for_authentication(:authentication_token => conditions[token_authentication_key])
          # ignore the account if the token is expired
          account = nil if account.present? && account.token_expired?
          account
        end
      end
    end
  end
end