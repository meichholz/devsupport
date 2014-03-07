require "cucumber/rake/task"

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

