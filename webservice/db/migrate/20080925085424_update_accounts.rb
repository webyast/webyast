class UpdateAccounts < ActiveRecord::Migration
  def self.up
    remove_column :accounts, :email
    remove_column :accounts, :crypted_password
    remove_column :accounts, :salt
  end

  def self.down
    add_column :accounts, :email, :string
    add_column :accounts, :crypted_password, :string
    add_column :accounts, :salt, :string
  end
end
