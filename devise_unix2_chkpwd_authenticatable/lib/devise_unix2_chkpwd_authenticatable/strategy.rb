require 'devise/strategies/base'

module Devise
  module Strategies
    class Unix2ChkpwdAuthenticatable < Base

      def valid?
        valid = valid_params? && mapping.to.respond_to?(:authenticate_with_unix2_chkpwd)
        Rails.logger.debug "valid?: #{valid}"
        valid
      end

      def authenticate!
        if resource = mapping.to.authenticate_with_unix2_chkpwd(params[scope])
          Rails.logger.error "*** Success!"
          success!(resource)
        else
          Rails.logger.error "*** Invalid!"
          fail(:invalid)
        end
      end

      protected

        def valid_controller?
          params[:controller] == 'devise/sessions'
        end

        def valid_params?
          params[scope] && params[scope][:password].present?
        end

    end
  end
end

Warden::Strategies.add(:unix2_chkpwd_authenticatable, Devise::Strategies::Unix2ChkpwdAuthenticatable)

