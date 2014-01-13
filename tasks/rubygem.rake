# rake support for standard gem projects with rspec and cucumber
#
# version: 1.0.3 - 8.10.2013
# version: 1.0.4 - 9.10.2013

require "rake/clean"
require 'rubygems/package_task'
require "cucumber/rake/task"

abort "set umask to 022, please" if File.umask!=022

@editor = "gvim" if @editor.nil?
@executable = FileList.new("bin/*")[0].to_s if @executable.nil?
@frontend = "bundle exec #{@executable}" if @frontend.nil?

CLEAN.include ["TAGS", "tags"]
CLEAN.include ["t","tt","*~"]
CLOBBER.include ["spec/reports", "features/reports", "features/result.json", "doc"]

# intentionally simplified
if @editfiles.nil?
  @editfiles = FileList.new(["bin/*", "[Rr]akefile", "*.gemspec",
                            "[Gg]emfile", "README.*", ]).to_s
end

desc "Fix permissions"
task :fixperm do
  sh "find . -type d | xargs chmod 755"
  sh "find . -not -type d | xargs chmod 644"
  sh "chmod a+x #{@executable}"
end

desc "Rebuild TAGS"
task :tags do
  sh "ctags --Ruby-kinds=+f -R --exclude=debian,pkg"
end

desc "Start edit and tagging"
task :edit => [ :tags ] do
  sh "#{@editor} #{@editfiles}"
end

desc "Push build up to our package server"
task :push => [ :build, :test, :package ] do
  Dir.chdir ".." do
    sh "rake push"
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

namespace :features do
  # http://www.ruby-doc.org/gems/docs/d/davidtrogers-cucumber-0.6.2/Cucumber/Rake/Task.html
  begin
    File.open("config/cucumber.yml") do |file|
      file.each_line do |line|
        if line=~/^(\w+):/ and $1!='default'
          tname = $1
          Cucumber::Rake::Task.new(tname, "Run cuke profile #{tname}") do |t|
            t.profile = tname
            t.cucumber_opts = "-r ./features"
          end
        end
      end
    end
  rescue Errno::ENOENT => err
    # generic task
    desc "FIXME: add config/cucumber.yml with check profile"
    task :check do
      sh "bundle exec cucumber -r features"
    end
  end

  desc "Create features"
  task :report do
    sh "test -d doc || mkdir doc"
    sh "bundle exec cucumber -f html -o features/index.html -f pretty --no-color -o features/index.text -r features"
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

# TODO: flexiby and intelligize these tasks!
namespace :man do
  desc "Build manpage(s)"
  task :build => [ "man/#{@program_name}.1" ]
  task "man/#{@program_name}.1" => [ "man/#{@program_name}.1.ronn" ] do
    sh "#{@env_ronn} man/#{@program_name}.1.ronn"
  end

  desc "View manpage"
  task :view => :build do
    sh "man -l man/#{@program_name}.1"
  end
end

namespace :doc do
  desc "Build integrated documentation with rdoc" 
  task :rdoc do
    sh "#{@env_rdoc} -q -a README.rdoc lib/#{@program_name}/*.rb"
  end
  desc "Build integrated documentation with yard"
  task :yard do
    sh "yard"
    sh "yard graph --full | dot -T svg -o doc/diagram.svg"
  end
  desc "View doc"
  task :view => [ :build ] do
    sh "#{@env_browser} doc/index.html"
    puts "You may now run: rake test && rake stage"
  end
end

