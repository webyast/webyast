class RenameUserColumns < ActiveRecord::Migration
  def self.up
    rename_column :users, :fullName, :full_name
    rename_column :users, :defaultGroup, :default_group
    rename_column :users, :homeDirectory, :home_directory
    rename_column :users, :loginShell, :login_shell
    rename_column :users, :loginName, :login_name
    rename_column :users, :ldapPassword, :ldap_password
    rename_column :users, :newUid, :new_uid
    rename_column :users, :newLoginName, :new_login_name
    rename_column :users, :noHome, :no_home
  end

  def self.down
    rename_column :users, :full_name, :fullName
    rename_column :users, :default_group, :defaultGroup
    rename_column :users, :home_directory, :homeDirectory
    rename_column :users, :login_shell, :loginShell
    rename_column :users, :login_name, :loginName
    rename_column :users, :ldap_password, :ldapPassword
    rename_column :users, :new_uid, :newUid
    rename_column :users, :new_login_name, :newLoginName
    rename_column :users, :no_home, :noHome
  end
end
