class ChangeServicesColumnName < ActiveRecord::Migration
  def self.up
    rename_column :services, :name, :link
  end

  def self.down
    rename_column :services, :link, :name
  end
end
