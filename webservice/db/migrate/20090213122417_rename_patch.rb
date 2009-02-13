class RenamePatch < ActiveRecord::Migration
  def self.up
    rename_column :patch_updates, :resolvableId, :resolvable_id
  end

  def self.down
    rename_column :patch_updates, :resolvable_id, :resolvableId
  end
end
