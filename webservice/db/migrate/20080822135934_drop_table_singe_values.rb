class DropTableSingeValues < ActiveRecord::Migration
  def self.up
    drop_table :single_values
  end

  def self.down
    create_table :single_values do |t|
      t.string :name
      t.string :value
    end
  end
end
