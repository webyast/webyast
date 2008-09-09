class AddANewColumnUsers < ActiveRecord::Migration
  def self.up
     add_column :users, :password, :string
     add_column :users, :ldapPassword, :string
     add_column :users, :type, :string
     add_column :users, :newUid, :string
     add_column :users, :newLoginName, :string
     add_column :users, :noHome, :boolean
  end

  def self.down
    remove_column :users, :password
    remove_column :users, :ldapPassword
    remove_column :users, :type
    remove_column :users, :newUid
    remove_column :users, :newLoginName
    remove_column :users, :noHome
  end
end
