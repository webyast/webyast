require 'devise_unix2_chkpwd_authenticatable/strategy'
require 'devise_unix2_chkpwd_authenticatable/session'

module Devise
  module Models
    module Unix2ChkpwdAuthenticatable

      def self.included(base)
        base.class_eval do
          extend ClassMethods
          attr_accessor :password
        end
      end

      # Set password to nil
      def clean_up_passwords
        self.password = nil
      end

      def unix2_chkpwd(login, passwd)
        cmd = "/sbin/unix2_chkpwd passwd '#{login}'"
        session = Session.new
        result, err = session.execute cmd, :stdin => passwd
        ret = session.get_status.zero?
        session.close
        ret
      end


      module ClassMethods

        def authenticate_with_unix2_chkpwd(attributes={})
         return nil unless attributes[:username].present?

         resource = scoped.where(:username => attributes[:username]).first

         if resource.blank?
           resource = new
           resource[:username] = attributes[:username]
           resource[:password] = attributes[:password]
         end

         if resource.try(:unix2_chkpwd, attributes[:username], attributes[:password])
           resource.save if resource.new_record?
           Rails.logger.info "User #{attributes[:username]} successfully authenticated"
           return resource
         else
           Rails.logger.info "User #{attributes[:username]} authentication failed"
           return nil
         end

       end

     end

    end
  end
end
