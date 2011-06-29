class CreateHosts < ActiveRecord::Migration
  def self.up
    create_table "hosts", :force => true do |t|
      t.string   "name"
      t.string   "url"
      t.text     "description"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
    drop_table :hosts
  end
end
