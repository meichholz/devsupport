# rake support for standard gem projects with rspec and cucumber
#
# version: 1.0.1 - 11.9.2013
# version: 1.0.2 - 17.9.2013
# version: 1.0.3 - 8.10.2013

require "rake/clean"
require 'rubygems/package_task'
require "cucumber/rake/task"
require "ci/reporter/rake/cucumber"
require "ci/reporter/rake/rspec"

abort "set umask to 022, please" if File.umask!=022

@editor = "gvim" if @editor.nil?
@executable = FileList.new("bin/*")[0].to_s if @executable.nil?
@frontend = "bundle exec #{@executable}" if @frontend.nil?

CLEAN.include(["TAGS", "tags"])

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
    sh "bundle exec rspec -f html -o doc/spec.html -f doc -o doc/spec.text"
  end

  desc "Run rspec unit tests"
  task :rspec do
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
      sh "cucumber -r features"
    end
  end

  desc "Create features"
  task :report do
    sh "test -d doc || mkdir doc"
    sh "bundle exec cucumber -P -f html -o doc/features.html -f pretty --no-color -o doc/features.text -r features"
  end

end

namespace :test do

  desc "Run all regression tests"
  task :all => [ :rspec, 'features:check' ]

  desc "Check Work in Progress"
  task :wip => [ :rspec, 'features:wip' ]

end

namespace :cov do

  desc "export test coverage in spec/report"
  task :rspec => "ci:setup:rspec" do
    sh "bundle exec rspec"
  end

  task :cucumber => "ci:setup:cucumber" do
    sh "bundle exec cucumber --format=CI::Reporter::Cucumber"
  end
  desc "export coverage for everything"
  task :all => [ :clearset, :rspec, :cucumber ]

  desc "view the combined html"
  task :view do
    sh "epiphany coverage/rcov/index.html"
  end

  task :clearset do
    cachefile="coverage/.resultset.json"
    FileUtils .rm cachefile if File.exists? cachefile
  end
end

