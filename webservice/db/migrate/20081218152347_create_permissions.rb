class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.string :name
      t.boolean :grant
      t.integer :error_id
      t.string  :error_string
    end
  end

  def self.down
    drop_table :permissions
  end
end
