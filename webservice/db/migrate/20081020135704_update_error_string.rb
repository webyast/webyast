class UpdateErrorString < ActiveRecord::Migration
  def self.up
    remove_column :users, :error_string
    remove_column :config_ntps, :error_string
    remove_column :languages, :error_string
    remove_column :patch_updates, :error_string
    remove_column :services, :error_string
    remove_column :system_times, :error_string
    add_column :users, :error_string, :string, :default =>""
    add_column :config_ntps, :error_string, :string, :default =>""
    add_column :languages, :error_string, :string, :default =>""
    add_column :patch_updates, :error_string, :string, :default =>""
    add_column :services, :error_string, :string, :default =>""
    add_column :system_times, :error_string, :string, :default =>""
  end

  def self.down
    remove_column :users, :error_string
    remove_column :config_ntps, :error_string
    remove_column :languages, :error_string
    remove_column :patch_updates, :error_string
    remove_column :services, :error_string
    remove_column :system_times, :error_string
    add_column :users, :error_string, :string, :null => false, :default =>""
    add_column :config_ntps, :error_string, :string, :null => false, :default =>""
    add_column :languages, :error_string, :string, :null => false, :default =>""
    add_column :patch_updates, :error_string, :string, :null => false, :default =>""
    add_column :services, :error_string, :string, :null => false, :default =>""
    add_column :system_times, :error_string, :string, :null => false, :default =>""
  end
end
