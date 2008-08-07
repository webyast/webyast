class DropTableNtps < ActiveRecord::Migration
  def self.up
    drop_table :service_ntps
  end

  def self.down
  end
end
