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
  [ "rspec" ],
  [ "cucumber" ],
  [ "ci_reporter" ],
  [ "simplecov-rcov" ],
  ]
  opt.license = "MIT"
  opt.rspec_options = [ "--color", "--require", "rspec_helper.rb" ]
  opt.cucumber_options = [ "" ]
  opt.extra_files = [ ] # to go into manifest/package
end

ds_raker.assert_sanity

# @todo care about `config/cucumber.yml` that could read:
#     default: --tags ~@mail
#     check: --format progress --tags ~@wip --tags ~@mail --strict
#     mail: --tags @mail
#     wip: --tags @wip

# wrapper around {Hoe.spec} DRYing out things even further. *Mandatory call*
def ds_hoe_spec(projectname, &block)
  Hoe.spec(projectname) do
    block.call(self)
    self.rspec_options = ds_env.rspec_options
    ds_env.dev_deps.each do |spec|
      extra_dev_deps << spec
    end
    license ds_env.license
    ds_env.yard_options.each do |opt|
      self.yard_options += opt
    end
  end
end

# define tasks by hoe itself, giving nicer description string
$LOAD_PATH << File.join([ File.dirname(__FILE__), 'hoe_plugins' ])
Hoe.plugin :devsupport
Hoe.plugin :yard
Hoe.plugin :bundler


