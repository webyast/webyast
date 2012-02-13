
# increase the default memory for spidermoneky JS engine used by johnson gem
# (from 32M to 64M) to avoid "spidermonkey ran out of memory" error
namespace :assets do
  task :extra_memory do
    ENV["JOHNSON_HEAP_SIZE"] = "64000000"
  end

  # split manifest file to serate JS and style parts
  desc "Split public/assets/manifest.yml file to sparate parts for base and default-branding"
  task :split_manifest do
    require 'yaml'

    manifest = YAML.load_file "public/assets/manifest.yml"

    manifest_base = {}
    manifest_branding = {}

    manifest.each do |source, target|
      if source.match /\.js$/
        manifest_base[source] = target
      else
        manifest_branding[source] = target
      end
    end

    File.open("public/assets/manifest.yml.base", "w") do |file|
      file.puts manifest_base.to_yaml
    end

    File.open("public/assets/manifest.yml.branding-default", "w") do |file|
      file.puts manifest_branding.to_yaml
    end
  end

  desc "Join public/assets/manifest.yml.* files to single manifest.yml file"
  task :join_manifests do
    require 'yaml'

    merged = Dir.glob("public/assets/manifest.yml.*").inject({}) do | sum, file |
      sum.merge(YAML.load_file file)
    end

    File.open("public/assets/manifest.yml", "w") do |file|
      file.puts merged
    end
  end
end

# set the environment before executing the task
task :'assets:precompile' => :'assets:extra_memory'