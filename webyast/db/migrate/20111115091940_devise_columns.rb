
require 'devise/version'

class DeviseColumns < ActiveRecord::Migration
  def up
    change_table(:accounts) do |t|
      t.rename :login, :username
      #t.rememberable

      if Devise::VERSION.match /^2\./
        ## Trackable
        t.integer  :sign_in_count, :default => 0
        t.datetime :current_sign_in_at
        t.datetime :last_sign_in_at
        t.string   :current_sign_in_ip
        t.string   :last_sign_in_ip
      else
        t.trackable
      end
      # rememberable uses remember_token, but this field is different
      t.rename :remember_token_expires_at, :remember_created_at
      # these fields are named differently in devise
      #t.rename :crypted_password, :encrypted_password
    end
  end

  #def down
    #drop_table :users
  #end
end
