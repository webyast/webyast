class AddANewColumnUserSshkey < ActiveRecord::Migration
  def self.up
    add_column :users, :sshkey, :string
  end

  def self.down
    remove_column :users, :sshkey
  end
end
