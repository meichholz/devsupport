CLEAN.include ".yardoc", "*~", "t", "tt"

namespace :dev do
  desc "Bump modules to upstream"
  task :update do
    sema = Devsupport::Rake.upstream_semaphore
    FileUtils.rm sema if File.exists?(sema)
    [ "devsupport", "googletest" ].each do |dir|
      puts ">>> bumping #{dir} to upstream"
      if File.exists? dir
        Dir.chdir dir do
          sh "git pull origin master"
        end
      end
    end
  end

  desc "Use upstream submodules"
  task :upstream do
    touch Devsupport::Rake.upstream_semaphore
  end

  desc "Show configuration"
  task :info do
    ds_raker.option_hash.each do |key, value|
      puts "#{key} => #{value}"
    end
  end

end
