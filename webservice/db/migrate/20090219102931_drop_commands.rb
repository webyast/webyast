class DropCommands < ActiveRecord::Migration
  def self.up
     drop_table "commands"
  end

  def self.down
  end
end
