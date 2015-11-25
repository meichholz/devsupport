# note: these tasks will end up in name space "ds"

load File.join(File.dirname(__FILE__), 'rake_abandon.rb')

CLEAN.include ".yardoc", "*~", "t", "tt"

desc "Bump modules to upstream"
task :pull do
  sema = ds_env.upstream_semaphore
  FileUtils.rm sema if File.exists?(sema)
  [ '3rdparty', 'devsupport', 'googletest' ].each do |dir|
    if File.exists? dir
      puts ">>> bumping #{dir} to upstream"
      Dir.chdir dir do
        sh "git pull origin master"
      end
    end
  end
end

desc "Use upstream submodules"
task :upstream do
  touch ds_env.upstream_semaphore
end

desc "Show environment and configuration"
task :env do
  options = ds_raker.option_hash
  options.keys.sort.each do |key|
    printf "%24s := %s\n", key, options[key]
  end
end

desc "Conclude environment details from user setup"
task :conclude do
end


