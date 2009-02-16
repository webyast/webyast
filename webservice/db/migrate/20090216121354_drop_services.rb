class DropServices < ActiveRecord::Migration
  def self.up
    drop_table "services"
  end

  def self.down
  create_table "services", :force => true do |t|
    t.string  "link"
    t.string  "commands",     :default => "commands", :null => false
    t.string  "configs",      :default => "configs",  :null => false
    t.integer "error_id",     :default => 0,          :null => false
    t.string  "error_string", :default => ""
  end
end
end
