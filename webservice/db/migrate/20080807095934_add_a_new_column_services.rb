class AddANewColumnServices < ActiveRecord::Migration
  def self.up
    add_column :services, :commands, :string, :null => false, :default =>"commands"
    add_column :services, :configs,  :string, :null => false, :default =>"configs" 
  end

  def self.down
    remove_column :services, :commands
    remove_column :services, :configs
  end
end
