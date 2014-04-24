# rake support for HOE supported gems
# version: 1.0

require "rubygems"
require "hoe"

ds_raker.configure(defaults: true) do |opt|
  opt.mandatory_umask = 022
  opt.rvm_only = true
  opt.executable = FileList.new("bin/*")[0].to_s
  opt.program_name = File.basename(opt.executable, ".rb") 
  opt.frontend = "bundle exec #{opt.executable}"
  opt.editfiles = FileList.new("bin/*", "[Rr]akefile", "*.gemspec",
                               "[Gg]emfile", "README.*").to_s
  opt.directories = [ "bin", "lib" ]
  opt.yard_options = [
  [ '--files', 'BUILDING.md' ],
  ["--load", "#{File.join(ds_env.base_path, 'yard', 'standard', 'plugin.rb')}"],
  [ '--verbose' ],
  [ '--protected' ],
  [ '--private' ],
  [ '--hide-void-return' ],
  [ '--default-return', 'Unknown' ],
  ]
  opt.dev_deps = [
  [ "hoe-bundler", "~> 1.2" ],
  [ "yard" ],
  [ "redcarpet" ],
  ]
  opt.license = "MIT"
end

ds_raker.assert_sanity

# define tasks by hoe itself, giving nicer description string
$LOAD_PATH << File.join([ File.dirname(__FILE__), 'hoe_plugins' ])
Hoe.plugin :devsupport

Hoe.plugin :yard
Hoe.plugin :bundler

