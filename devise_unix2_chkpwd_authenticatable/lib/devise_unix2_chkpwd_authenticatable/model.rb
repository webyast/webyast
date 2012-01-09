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
        Rails.logger.error "*** UNIX2_CHKPWD #{login.inspect}"
        
        cmd = "/sbin/unix2_chkpwd passwd '#{login}'"
        session = Session.new
        result, err = session.execute cmd, :stdin => passwd
        ret = session.get_status.zero?
        session.close
        ret
      end


      module ClassMethods
    
        def authenticate_with_unix2_chkpwd(attributes={})
         Rails.logger.error "*** Authenticate with UNIX2_CHKPWD #{attributes.inspect}"
         return nil unless attributes[:username].present?

         resource = scoped.where(:username => attributes[:username]).first

         if resource.blank?
           resource = new
           resource[:username] = attributes[:username]
           resource[:password] = attributes[:password]
         end

         if resource.try(:unix2_chkpwd, attributes[:username], attributes[:password])
           resource.save if resource.new_record?
           return resource
         else
           return nil
         end
  
       end
  
     end
  
    end
  end
end

