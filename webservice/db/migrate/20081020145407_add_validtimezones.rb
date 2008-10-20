class AddValidtimezones < ActiveRecord::Migration
  def self.up
    add_column :system_times, :validtimezones, :string
  end

  def self.down
    remove_column :system_times, :validtimezones
  end
end
