class CreateDataCaches < ActiveRecord::Migration
  def self.up
    create_table :data_caches do |t|
      t.string :path
      t.string :session
      t.string :picked_md5
      t.string :refreshed_md5

      t.timestamps
    end
  end

  def self.down
    drop_table :data_caches
  end
end
