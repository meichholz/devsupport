module Hoe::DevSupport
  def define_devsupport_tasks # name by hoe framework

    CLEAN.include "spec/reports"
    CLOBBER.include "spec/index.html"
    CLEAN.include "coverage", "emigma.log"
    CLEAN.include "features/result.json", "features/reports"
    CLOBBER.include "features/index.html"

    namespace :ds do
      ds_tasks_for :common
      desc "Fix permissions"
      task :fixperm do
        ds_opt.directories.each do |dir|
          sh "find #{dir} -type d | xargs chmod 755"
          sh "find #{dir} -not -type d | xargs chmod 644"
        end
        sh "chmod a+x #{ds_env.executable}"
      end

      desc "Write new manifest"
      task :manifest do
        files = [
          'README.md',
          'History.md',
          'Manifest.txt',
          'BUILDING.md',
          'Rakefile',
          'Gemfile',
          'Gemfile.lock',
        ]
        Dir['bin/*'].each{|n| files << n }
        Dir['lib/**/*.rb'].each{|n| files << n }
        File.open("Manifest.txt", "w") do |f|
          files.each do |name|
            puts name
            f.puts name
          end
        end
      end
    end

    desc "Rebuild TAGS"
    task :tags do
      sh "ctags --Ruby-kinds=+f -R --exclude=debian,pkg"
    end

    desc "Start edit and tagging"
    task :edit => [ :tags ] do
      sh "#{ds_env.editor} #{ds_env.editfiles}"
    end

    desc "View yard doc"
    task 'view:doc' => :yard do
      sh "#{ds_env.browser} doc/index.html &"
    end

    desc "Push build up to our package server"
    task :push => [ :repackage ] do
      Dir.chdir ".." do
        sh "rake push"
      end
    end

# @todo coverage viewer and -cleanup
# @todo priming/rewriting of .gitignore

    desc "Cucumber"
    task :features do
      sh "bundle exec cucumber --format progress #{ds_env.cucumber_options.join(' ')}"
    end

    namespace :ci do

      desc "All tests in once"
      task :all => [ :clearset, :spec, :features ]

      desc "Rspec for Jenkins"
      task :spec do
        sh "bundle exec rspec #{ds_env.rspec_options.join(' ')} -f html -o spec/index.html -f CI::Reporter::RSpec"
      end

      desc "Cucumber for Jenkins"
      task :features do
        sh "bundle exec cucumber #{ds_env.cucumber_options.join(' ')} -f html -o features/index.html -f json -o features/result.json -f CI::Reporter::Cucumber"
      end

      desc "Clear caches and stuff"
      task :clearset do
        cachefile="coverage/.resultset.json"
        FileUtils .rm cachefile if File.exists? cachefile
      end

    end
  end
end

