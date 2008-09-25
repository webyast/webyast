class AddColumntAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :salt, :string
  end

  def self.down
    remove_column :accounts, :salt
  end
end
