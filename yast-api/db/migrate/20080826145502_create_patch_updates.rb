class CreatePatchUpdates < ActiveRecord::Migration
  def self.up
    create_table :patch_updates do |t|
      t.integer :resolvableId
      t.string :kind
      t.string :name
      t.string :arch
      t.string :repo
      t.string :summary
    end
  end

  def self.down
    drop_table :patch_updates
  end
end
