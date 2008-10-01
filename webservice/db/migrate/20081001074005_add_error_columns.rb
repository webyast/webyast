class AddErrorColumns < ActiveRecord::Migration
  def self.up
    add_column :users, :error_id, :integer, :null => false, :default =>"0"
    add_column :users, :error_string, :string, :null => false, :default =>""
    add_column :config_ntps, :error_id, :integer, :null => false, :default =>"0"
    add_column :config_ntps, :error_string, :string, :null => false, :default =>""
    add_column :languages, :error_id, :integer, :null => false, :default =>"0"
    add_column :languages, :error_string, :string, :null => false, :default =>""
    add_column :patch_updates, :error_id, :integer, :null => false, :default =>"0"
    add_column :patch_updates, :error_string, :string, :null => false, :default =>""
    add_column :services, :error_id, :integer, :null => false, :default =>"0"
    add_column :services, :error_string, :string, :null => false, :default =>""
    add_column :system_times, :error_id, :integer, :null => false, :default =>"0"
    add_column :system_times, :error_string, :string, :null => false, :default =>""
  end

  def self.down
    remove_column :users, :error_id
    remove_column :users, :error_string
    remove_column :config_ntps, :error_id
    remove_column :config_ntps, :error_string
    remove_column :languages, :error_id
    remove_column :languages, :error_string
    remove_column :patch_updates, :error_id
    remove_column :patch_updates, :error_string
    remove_column :services, :error_id
    remove_column :services, :error_string
    remove_column :system_times, :error_id
    remove_column :system_times, :error_string
  end
end
