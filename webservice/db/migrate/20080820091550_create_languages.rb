class CreateLanguages < ActiveRecord::Migration
  def self.up
    create_table :languages do |t|
      t.string :firstLanguage
      t.string :secondLanguages
    end
  end

  def self.down
    drop_table :languages
  end
end
