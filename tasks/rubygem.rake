# rake support for standard gem projects with rspec and cucumber
#
# version: 1.0.1 - 11.9.2013
# version: 1.0.2 - 17.9.2013

require "rake/clean"
require 'rubygems/package_task'
require "cucumber/rake/task"

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


