# rake support for standard gem projects with rspec and cucumber
#
# version: 1.1

ds_tasks_for :common

ds_raker.configure(defaults: true) do |opt|
  opt.mandatory_umask = 022
  opt.rvm_only = true
  opt.executable = FileList.new("bin/*")[0].to_s
  opt.program_name = File.basename(opt.executable, ".rb") 
  opt.frontend = "bundle exec #{opt.executable}"
  opt.editfiles = FileList.new("bin/*", "[Rr]akefile", "*.gemspec",
                               "[Gg]emfile", "README.*").to_s
  opt.gemspec = "#{opt.program_name}.gemspec"
end

ds_raker.assert_sanity

# needs rake/clean
CLOBBER.include "spec/reports", "features/reports", "features/result.json"
CLOBBER.include "doc", "coverage"

# this may break if no cucumber is installed at all
# and is practically overridden by rvm_only :-)
if ds_raker.have_rvm?
  ds_tasks_for :features
else
  STDERR.puts "WARNING: please develop with RVM for the development GEMs"
  STDERR.puts "WARNING: falling back to provision only functionality"
end

# glue tasks
task :default => :check
task :test => :check
task :check => 'test:all'
task 'doc:build' => 'doc:yard'

desc "Fix permissions"
task :fixperm do
  sh "find lib -type d | xargs chmod 755"
  sh "find lib -not -type d | xargs chmod 644"
  sh "chmod a+x #{ds_env.executable}"
end

desc "Rebuild TAGS"
task :tags do
  sh ds_env.ctags
end

desc "Start edit and tagging"
task :edit => [ :tags ] do
  sh "#{ds_env.editor} #{ds_env.editfiles}"
end

if File.exists?(ds_env.gemspec)
  require "rubygems/package_task"
  load ds_env.gemspec
  if @gemspec
    Gem::PackageTask.new(@gemspec) do |pkg|
      pkg.need_zip = true
    end
    desc "Push build up to our package server"
    task :push => [ :build, :test, :repackage ] do
      Dir.chdir ".." do
        sh "rake push"
      end
    end
  else
    raise "please assign @gemspec in #{ds_env.gemspec}"
  end
end

namespace :spec do
  desc "Create specs"
  task :report do
    sh "test -d doc || mkdir doc"
    sh "bundle exec rspec -f html -o spec/index.html -f doc -o spec/index.text"
  end

  desc "Run rspec unit tests"
  task :all do
    IO.popen("bundle exec rspec --no-color") do |rspec|
      rspec.each_line do |line|
        # strip off error comment on failing SUT code
        line.chomp!
        line.gsub!(/^ {5}\# /,"")
          puts line
      end
    end
    fail if $?.exitstatus != 0
  end
end

namespace :test do

  desc "Run all regression tests"
  task :all => [ 'spec:all', 'features:check' ]

  desc "Check Work in Progress"
  task :wip => [ 'spec:all', 'features:wip' ]

end

namespace :ci do

  desc "test and export RSpec results"
  task :spec do
    sh "bundle exec rspec -f html -o spec/index.html"
    sh "bundle exec rspec -f CI::Reporter::RSpec"
  end

  desc "test and export cucumber results"
  task :features do
    format = "CI::Reporter::Cucumber"
    sh "bundle exec cucumber -f html -o features/index.html -f json -o features/result.json -f #{format}"
  end
  desc "report on everything"
  task :all => [ :clearset, :spec, :features ]

  desc "view the combined html"
  task :view do
    sh "epiphany coverage/rcov/index.html"
  end

  task :clearset do
    cachefile="coverage/.resultset.json"
    FileUtils .rm cachefile if File.exists? cachefile
  end
end

# TODO: flexify and intelligize these tasks!

task "man/#{ds_env.program_name}.1" => [ "man/#{ds_env.program_name}.1.ronn" ] do
  sh "#{ds_env.ronn} man/#{ds_env.program_name}.1.ronn"
end
namespace :man do
  desc "Build manpage(s)"
  task :build => [ "man/#{ds_env.program_name}.1" ]

  desc "View manpage"
  task :view => :build do
    sh "man -l man/#{ds_env.program_name}.1"
  end
end

namespace :doc do
  desc "Build integrated documentation with rdoc" 
  task :rdoc do
    sh "#{ds_env.rdoc} -q -a README.rdoc lib/#{ds_env.program_name}/*.rb"
  end
  desc "Build integrated documentation with yard"
  task :yard do
    sh "yard"
    sh "yard graph --full | dot -T svg -o doc/diagram.svg"
  end
  desc "View doc"
  task :view => [ :build ] do
    sh "#{ds_env.browser} doc/index.html"
    puts "You may now run: rake test && rake stage"
  end
end

