require 'rubygems'
require 'session'

begin
  require "rpam"
  include Rpam
rescue
  $stderr.puts "ruby-rpam not found!"
  exit
end

require 'digest/sha1'

class Account < ActiveRecord::Base
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login
  validates_presence_of     :password,                   :if => :password_required?
  validates_length_of       :password, :within => 1..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 1..40
  validates_uniqueness_of   :login, :case_sensitive => false
  before_save :encrypt_password
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :password

  # Authenticates a user by their login name and unencrypted password with unix2_chkpwd
  def self.unix2_chkpwd(login, passwd)
     cmd = "/sbin/unix2_chkpwd rpam " + login
     se = Session.new
     result, err = se.execute cmd, :stdin => passwd
     if (se.get_status == 0)
        return true
     else
        return false
     end
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, passwd)
     granted = false
     begin
       granted = false
       if authpam(login,passwd) == true or    #much more faster
          unix2_chkpwd(login,passwd)          #slowly but need no more additional PAM rights
          granted = true
       end
     rescue #caused by authpam
       if unix2_chkpwd(login,passwd)          #slowly but need no more additional PAM rights
          granted = true
       end
     end
     if granted
	acc = find_by_login(login)
	if !acc
          acc = Account.new
          acc.login = login
        end
        @password = passwd
        acc.password = passwd
        acc.save
        return acc
     else
        return nil
     end
  end

  # Encrypts some data with the salt.
  def self.encrypt(data, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{data}--")
  end

  # Encrypts the data with the user salt
  def encrypt(data)
    self.class.encrypt(data, salt)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
#    remember_me_for 2.weeks
    remember_me_for 1.days
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{login}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    end
      
    def password_required?
      !password.blank?
    end
    
    
end
