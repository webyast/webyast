
class Restdoc

  def self.find(what)
    # TODO: 'what' parameter is currently unused

    @ret = []
    Rails.configuration.plugin_paths.each do |path|
      plugins = Dir["#{path}/*"]

      plugins.each do |plugin|
        if File.directory?("#{plugin}/app") && File.directory?("#{plugin}/public")

          Dir["#{plugin}/public/**/restdoc/index.html"].each do |restdoc_path|
            if File.file? "#{restdoc_path}"
              m = /\/public\/(.*\/restdoc\/index.html)/.match(restdoc_path)

              @ret << m[1]
            end
          end
        end
      end
    end

    return @ret
  end
end