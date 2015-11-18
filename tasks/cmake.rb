# this task bundle assumes
# - CMakeLists.txt
# - build in "build_dir"
# - source inside "src"
# - tests in "tests"
#
# Full debug build: rake clobber ds:test:on build

ds_tasks_for :ccommon

def get_appname
  appname = nil
  FileList.new(["**/CMakeLists.txt"]).each do |fitem|
    File.open fitem, "rb" do |f|
      f.each_line do |l|
        m = l.match(/^install\s*\(TARGETS (\w+) DESTINATION bin\)/)
        appname ||= m[1] if m
      end
    end
  end
  appname
end

@appname = get_appname

ds_configure(defaults: true) do |c|
  c.appname = @appname
  c.build_dir = 'build_dir'
  c.executable = File.join(c.sourcedir, @appname)
  c.cmake_base_options = "-DCMAKE_INSTALL_PREFIX:PATH=/usr"
  c.frontend = c.executable
  c.editfiles = FileList.new("**/CMakeLists.txt", "README*" )
  # do NOT preset c.sut without any need!
end

# @todo that mechanism is brittle and should be replaced by something cleaner
# this task is called back by Devsupport.ds_conclude
task :'ds_conclude' do
  ds_configure(defaults: true) do |c|
    c.gcov_bin='gcov'
  end
  ds_ccommon_post_configure
end

task :default => :check

desc "Reconfigure the source"
task :reconf => [ :tidyup, :configure ]

desc "Clean up build directory"
task :tidyup do
  FileUtils.rm_rf ds_env.build_dir if File.exists?(ds_env.build_dir)
end

task :clobber => :tidyup

desc "Configure via CMAKE"
task :configure do
  FileUtils.mkdir ds_env.build_dir unless  File.exists?(ds_env.build_dir)
  Dir.chdir ds_env.build_dir do
    sh "cmake #{ds_env.cmake_base_options} #{ds_env.cmake_options} #{ds_env.root_dir}"
  end
end

desc "Build the application"
task :build => :configure do
  Dir.chdir ds_env.build_dir do
    sh "#{ds_env.make_bin}" # VERBOSE=1
  end 
end

desc "Run full test suite"
task :check => 'test:suite'

desc "Build packages"
task :package => :build do
  Dir.chdir ds_env.build_dir do
    system("cpack #{ds_env.root_dir}")
    sh("dpkg --contents *.deb")
  end 
end

# ========== documentation and asset generation  =======================

namespace :doc do
  desc "Show dependency graph"
  task :depgraph => :configure do
    Dir.chdir ds_env.build_dir do
      sh "cmake --graphviz=depdot #{ds_env.cmake_base_options} #{ds_env.cmake_options} #{ds_env.root_dir}"
      sh "dot -Tps < depdot >depdot.ps"
      sh "evince depdot.ps"
    end
  end

  desc "Build doxygen documentation"
  task :doxygen do
    FileUtils.rm_rf 'doxygen' if File.exists? 'doxygen'
    FileUtils.mkdir 'doxygen'
    sh "doxygen"
    puts "now reload Your brower, or point it to"
    puts "file:///home/marian/pm-git/software/mguardd/trunk/doxygen/html/index.html"
    puts "doxygen/html/index.html"
  end

  desc "Build all documentation for jenkins"
  task :all => [ :doxygen ]

end


