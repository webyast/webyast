class CreateConfigNtps < ActiveRecord::Migration
  def self.up
    create_table :config_ntps do |t|
      t.boolean :enabled
      t.boolean :use_random_server
      t.string :manual_server
    end
  end

  def self.down
    drop_table :config_ntps
  end
end
