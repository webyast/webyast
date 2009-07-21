desc "Create mo-files for L10n"
task :makemo do
    require 'gettext_rails/tools'
      GetText.create_mofiles
end


