class CreateSysconfigs < ActiveRecord::Migration
  def self.up
    create_table :sysconfigs do |t|
      t.string :name
    end
  end

  def self.down
    drop_table :sysconfigs
  end
end
