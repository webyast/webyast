class ChangeSystemTimeColumnTime < ActiveRecord::Migration
  def self.up
   rename_column :system_times, :systemtime, :currenttime
  end

  def self.down
   rename_column :system_times, :currenttime, :systemtime
  end
end
