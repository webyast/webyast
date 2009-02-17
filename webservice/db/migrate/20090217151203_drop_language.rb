class DropLanguage < ActiveRecord::Migration
  def self.up
    drop_table "sysconfigs"
    drop_table "languages"
  end

  def self.down
    create_table "sysconfigs", :force => true do |t|
      t.column :name,                     :string
    end
    create_table "languages", :force => true do |t|
      t.string  "first_language"
      t.string  "second_languages"
      t.string  "available"
      t.integer "error_id",         :default => 0,  :null => false
      t.string  "error_string",     :default => ""
    end
  end
end
