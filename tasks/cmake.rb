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

# ========== debugging support ====================

namespace :test do
  desc "Run ds_env.frontend program through valgrind"
  task :grind => 'build' do
    Dir.chdir ds_env.build_dir do
      system "valgrind --leak-check=full --show-reachable=yes #{ds_env.frontend} #{ds_env.run_arguments}"
    end
  end

  desc "Run cucumber"
  task :cucumber => 'build' do
    Dir.chdir "#{ds_env.build_dir}/#{ds_env.features}" do
      sh "cucumber #{ds_env.root_dir}/#{ds_env.features}"
    end
  end

  desc "Run all tests"
  task :suite => 'build' do
    Dir.chdir ds_env.build_dir do
      ENV["GTEST_COLOR"]="yes"
      system("#{ds_env.make_bin} test")
    end 
  end
end

# ========== code coverage =======================
namespace :cov do

  desc "Run the SUT, producing coverage data"
  task :run => 'build' do
    output="#{ds_env.build_dir}/tests/unit/reports/"
    sh "#{ds_env.sut} --gtest_output=xml:#{output}"
  end

  desc "Use LCOV for transformation (deprecated)"
  task :lcov => :run do
    sh "lcov --capture --directory #{ds_env.build_dir}/src --output-file #{ds_env.build_dir}/coverage.info"
    sh "genhtml #{ds_env.build_dir}/coverage.info --output-directory #{ds_env.build_dir}/lcov"
    sh "epiphany #{ds_env.build_dir}/lcov/index.html &"
end

  desc "Check coverage in browser"
  task :html => :run do
    sh "#{ds_env.gcovr_bin} #{ds_env.gcovr_opt} --html --html-details -o #{ds_env.build_dir}/gcov.html"
    sh "epiphany #{ds_env.build_dir}/gcov.html &"
    puts "see: #{ds_env.build_dir}/gcov.html"
  end

  desc "Export gtest coverage"
  task :gtest => :run do
    sh "#{ds_env.gcovr_bin} #{ds_env.gcovr_opt} --xml -o #{ds_env.build_dir}/coverage.xml"
  end

  desc "Export cucumber coverage"
  task :features => 'build' do
    Dir.chdir "#{ds_env.build_dir}/#{ds_env.features}" do
      sh "cucumber -f json -o result.json -f junit -o reports #{ds_env.root_dir}/#{ds_env.features}"
    end
  end

  desc "Export all coverages"
  task :all => [ :gtest, :features ]

  desc "Export coverage for jenkins"
  task :text => :run do
    sh "#{ds_env.gcovr_bin} #{ds_env.gcovr_opt}"
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


