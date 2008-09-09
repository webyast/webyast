class CreateSingleValues < ActiveRecord::Migration
  def self.up
    create_table :single_values do |t|
      t.string :name
      t.string :value
    end
  end

  def self.down
    drop_table :single_values
  end
end
