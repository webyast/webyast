class ChangeSystemTimeColumnName < ActiveRecord::Migration
  def self.up
    rename_column :system_times, :system_time, :systemtime
  end

  def self.down
    rename_column :system_times, :systemtime, :system_time
  end
end
