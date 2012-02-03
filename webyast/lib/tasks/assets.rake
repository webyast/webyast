
# increase the default memory for spidermoneky JS engine used by johnson gem
# (from 32M to 64M) to avoid "spidermonkey ran out of memory" error
namespace :assets do
  task :extra_memory do
    ENV["JOHNSON_HEAP_SIZE"] = "64000000"
  end
end

# set the environment before executing the task
task :'assets:precompile' => :'assets:extra_memory'