class DropDataCache < ActiveRecord::Migration
  def self.up
    drop_table :data_caches
  end

  def self.down
    create_table "data_caches" do |t|
      t.string   "path"
      t.string   "session"
      t.string   "picked_md5"
      t.string   "refreshed_md5"
      t.datetime "created_at",    :null => false
      t.datetime "updated_at",    :null => false
    end
  end
end
