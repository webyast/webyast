
require 'shellwords'
require 'pp'

require 'devise/strategies/base'


ActionController::Routing::Mapper.class_eval do
  protected
    alias_method :devise_pam_authenticatable, :devise_session
end

module Devise

  module PamAdapter

    # Authenticates a user by their login name and unencrypted password with unix2_chkpwd
    def self.unix2_chkpwd(login, passwd)
      puts "NOOOOOOOOOOOOOOOOO"
      return false if login.blank? or passwd.blank?
      return false if login.match("'") || login.match(/\\$/) #don't allow ' or \ in login to prevent security issues
      # RORSCAN_INL: This is not a CWE-184: Incomplete Blacklist
       login = Shellwords.escape(login) #just to be sure
       cmd = "/sbin/unix2_chkpwd rpam '#{login}'"
       se = Session.new
       result, err = se.execute cmd, :stdin => passwd #password needn't to be escaped as it is on stdin # RORSCAN_ITL
       ret = se.get_status.zero?
       # close the running shell
       se.close
       ret
    end

    def self.valid_credentials?(login, password)
      if Rails.env.test? && login = 'testadmin' && password == 'test' then
        # If we're running in the test environment then return true
        # if the login is testadmin and password is test
        return true;
      end
      PamAdapter.unix2_chkpwd(login, password)
    end

  end
end

module Devise
  module Strategies
    class PamAuthenticatable < Base
      
      def valid?
        puts "NOOOOOOOOOOOOOOOOO 1"
        return true
        valid_controller? && valid_params? && mapping.to.respond_to?(:authenticate_with_pam)
      end
      
      def authenticate!
        puts "NOOOOOOOOOOOOOOOOO 2"
        if resource = mapping.to.authenticate_with_pam(params[scope])
          success!(resource)
        else
          fail(:invalid)
        end
      end
      
      protected

        def valid_controller?
          puts "NOOOOOOOOOOOOOOOOO 3"
          params[:controller] == 'devise/sessions'
        end

        def valid_params?
          puts "NOOOOOOOOOOOOOOOOO 4"
          params[scope] && params[scope][:password].present?          
        end

    end
  end
end

Warden::Strategies.add(:pam_authenticatable, Devise::Strategies::PamAuthenticatable)

module Devise
  module Models
   module PamAuthenticatable

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

     # Checks if a resource is valid upon authentication.
     def valid_pam_authentication?(password)
       Devise::PamAdapter.valid_credentials?(self.login, password)
     end
     
     module ClassMethods
       def authenticate_with_pam(attributes={})
        puts attributes
         return nil unless attributes[:login].present?

         resource = scoped.where(:login => attributes[:login]).first
         if resource.blank?
           resource = new
           resource[:login] = attributes[:login]
           resource[:password] = attributes[:password]
         end

         if resource.try(:valid_pam_authentication?, attributes[:password])
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

Devise.add_module(:pam_authenticatable, :strategy => true, :model => "devise_pam_authenticatable/model", :route => true)

Devise.setup do |config|
  puts "HELLOO"
  require 'devise/orm/active_record'
  config.authentication_keys = [ :login ]
  config.default_scope = :account
  
  #config.warden do |manager|
    #manager.strategies.add(:pam, Devise::Strategies::PAM)
  #  manager.default_strategies(:scope => :account).unshift :pam
  #end
end

