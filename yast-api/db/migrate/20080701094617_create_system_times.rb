class CreateSystemTimes < ActiveRecord::Migration
  def self.up
    create_table :system_times do |t|
      t.datetime :system_time
      t.string :timezone
      t.boolean :is_utc
    end
  end

  def self.down
    drop_table :system_times
  end
end
