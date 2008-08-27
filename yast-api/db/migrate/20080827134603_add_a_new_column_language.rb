class AddANewColumnLanguage < ActiveRecord::Migration
  def self.up
    add_column :languages, :available, :string
  end

  def self.down
    remove_column :languages, :available
  end
end
