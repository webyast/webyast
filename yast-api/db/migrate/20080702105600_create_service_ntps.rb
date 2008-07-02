class CreateServiceNtps < ActiveRecord::Migration
  def self.up
    create_table :service_ntps do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :service_ntps
  end
end
