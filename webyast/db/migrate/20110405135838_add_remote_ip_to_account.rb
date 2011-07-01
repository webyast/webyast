class AddRemoteIpToAccount < ActiveRecord::Migration
  def self.up
    add_column :accounts, :remote_ip, :string
  end

  def self.down
    remove_column :accounts, :remote_ip
  end
end
