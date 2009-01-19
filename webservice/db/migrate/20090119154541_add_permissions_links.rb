class AddPermissionsLinks < ActiveRecord::Migration
  def self.up
    add_column :links, :read_permission, :boolean
    add_column :links, :write_permission, :boolean
    add_column :links, :execute_permission, :boolean
    add_column :links, :delete_permission, :boolean
    add_column :links, :install_permission, :boolean
    add_column :links, :new_permission, :boolean
  end

  def self.down
    remove_column :links, :read_permission
    remove_column :links, :write_permission
    remove_column :links, :execute_permission
    remove_column :links, :delete_permission
    remove_column :links, :install_permission
    remove_column :links, :new_permission
  end
end
