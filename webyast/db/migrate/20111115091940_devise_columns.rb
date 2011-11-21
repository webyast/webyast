
class DeviseColumns < ActiveRecord::Migration
  def up
    change_table(:accounts) do |t|
      t.rename :login, :username
      #t.rememberable
      t.trackable
      # rememberable uses remember_token, but this field is different
      t.rename :remember_token_expires_at, :remember_created_at
      # these fields are named differently in devise
      #t.rename :crypted_password, :encrypted_password
    end
    rename_table(:accounts, :users)
  end

  #def down
    #drop_table :users
  #end
end
