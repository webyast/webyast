class RenameLanguage < ActiveRecord::Migration
  def self.up
    rename_column :languages, :firstLanguage, :first_language
    rename_column :languages, :secondLanguages, :second_languages
  end

  def self.down
    rename_column :languages, :first_language, :firstLanguage
    rename_column :languages, :second_languages, :secondLanguages
  end
end
