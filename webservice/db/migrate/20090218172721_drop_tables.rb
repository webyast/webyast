class DropTables < ActiveRecord::Migration
  def self.up
    drop_table "config_ntps"
    drop_table "links"
    drop_table "patch_updates"
    drop_table "permissions"
    drop_table "system_times"
    drop_table "users"
  end

  def self.down
  create_table "config_ntps", :force => true do |t|
    t.boolean "enabled"
    t.boolean "use_random_server"
    t.string  "manual_server"
    t.integer "error_id",          :default => 0,  :null => false
    t.string  "error_string",      :default => ""
  end

  create_table "links", :force => true do |t|
    t.string  "path"
    t.string  "description"
    t.boolean "read_permission"
    t.boolean "write_permission"
    t.boolean "execute_permission"
    t.boolean "delete_permission"
    t.boolean "install_permission"
    t.boolean "new_permission"
  end

  create_table "patch_updates", :force => true do |t|
    t.integer "resolvable_id"
    t.string  "kind"
    t.string  "name"
    t.string  "arch"
    t.string  "repo"
    t.string  "summary"
    t.integer "error_id",      :default => 0,  :null => false
    t.string  "error_string",  :default => ""
  end

  create_table "permissions", :force => true do |t|
    t.string  "name"
    t.boolean "grant"
    t.integer "error_id"
    t.string  "error_string"
  end

  create_table "sysconfigs", :force => true do |t|
    t.string "name"
  end

  create_table "system_times", :force => true do |t|
    t.datetime "currenttime"
    t.string   "timezone"
    t.boolean  "is_utc"
    t.integer  "error_id",       :default => 0,  :null => false
    t.string   "error_string",   :default => ""
    t.string   "validtimezones"
  end

  create_table "users", :force => true do |t|
    t.string  "full_name"
    t.string  "groups"
    t.string  "default_group"
    t.string  "home_directory"
    t.string  "login_shell"
    t.string  "login_name"
    t.string  "uid"
    t.string  "password"
    t.string  "ldap_password"
    t.string  "type"
    t.string  "new_uid"
    t.string  "new_login_name"
    t.boolean "no_home"
    t.string  "sshkey"
    t.integer "error_id",       :default => 0,  :null => false
    t.string  "error_string",   :default => ""
  end

  end
end
