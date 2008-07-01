class CreateSystemTimes < ActiveRecord::Migration
  def self.up
    create_table :system_times do |t|
      t.datetime :system_time
      t.string :timezone
      t.boolean :is_utc

      t.timestamps
    end
  end

  def self.down
    drop_table :system_times
  end
end
