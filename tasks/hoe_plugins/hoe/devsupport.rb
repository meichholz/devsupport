module Hoe::DevSupport
  def define_devsupport_tasks

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
  end
end

