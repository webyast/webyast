class CreateLinks < ActiveRecord::Migration
  def self.up
   create_table "links", :force => true do |t|
      t.column :path,                     :string
      t.column :description,              :string
   end
  end

  def self.down
    drop_table "links"
  end
end
