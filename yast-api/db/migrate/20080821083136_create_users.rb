class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :fullName
      t.string :groups
      t.string :defaultGroup
      t.string :homeDirectory
      t.string :loginShell
      t.string :loginName
      t.string :uid
    end
  end

  def self.down
    drop_table :users
  end
end
