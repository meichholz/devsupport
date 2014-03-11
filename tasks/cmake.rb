ds_tasks_for :common

appname = nil
FileList.new(["**/CMakeLists.txt"]).each do |fitem|
  File.open fitem, "rb" do |f|
    f.each_line do |l|
      m = l.match(/^install\s*\(TARGETS (\w+) DESTINATION bin\)/)
      appname ||= m[1] if m
    end
  end
end

ds_configure(defaults: true) do |c|
  c.appname = appname
  c.build_dir = 'build_dir'
  c.executable = File.join("src", appname)
  c.cmake_base_options = "-DCMAKE_INSTALL_PREFIX:PATH=/usr"
  c.cmake_options = nil
  c.concurrency = 4
  c.root_dir = Dir.pwd
  c.build_dir = "build_dir"
  c.frontend = c.executable
  c.features="tests/features"
  c.gcov_exclude = '^googletest'
  c.covr_bin = "devsupport/bin/gcovr"
  c.editfiles = FileList.new("**/CMakeLists.txt",
                            "src/*.c*", "README*" )
  c.scopefiles = FileList.new("src/**/*.c*", "src/**/*.h",
                              "tests/**/*.c*", "tests/**/*.h",
                              "tests/**/*.sh")
  c.gcc_versions = nil
end

def ds_cmake_configure
  version = nil
  if ds_env.gcc_versions
    ds_env.gcc_versions.each do |ver|
      if system("g++-#{ver} --version")
        puts "setting gcc-#{ver} as preferred compiler" if ds_env.debug_rake
        # CMAKE chooses the compiler through the environment
        version = ver
        break
      end
    end
  end
  if version
    ENV["CXX"] = "g++-#{version}"
    ENV["CC"]  = "gcc-#{version}"
    ENV["GCOV"]  = "gcov-#{version}"
  end
  ds_configure(defaults: true) do |c|
    c.make = "make -j#{ds_env.concurrency}"
    c.gcov_bin = version ? "gcov-#{version}" : "gcov"
    c.gcovr_opt = "--gcov-executable=#{c.gcov_bin} -r . --branches -u -e '#{ds_env.gcov_exclude}'"
    c.sut = "#{ds_env.build_dir}/tests/unit/test_main"
  end
  if ds_env.debug_rake
    puts "DEBUG: build_dir is #{ds_env.build_dir}"
    puts "DEBUG: root_dir is #{ds_env.root_dir}"
    puts "DEBUG: gcc-version is #{version}"
  end
end


CLEAN.include "t", "tt*", "*~"
CLEAN.include "tags", "cscope.out"
CLOBBER.include ds_env.build_dir


task :default => :check

desc "reconfigure the source"
task :reconf => [ :tidyup, :configure ]

desc "clean up build directory"
task :tidyup do
  FileUtils.rm_rf ds_env.build_dir if File.exists?(ds_env.build_dir)
end

desc "configure via cmake"
task :configure do
  unless File.exists? ds_env.build_dir
    FileUtils.mkdir ds_env.build_dir
    Dir.chdir ds_env.build_dir do
      sh "cmake #{ds_env.cmake_base_options} #{ds_env.cmake_options} #{ds_env.root_dir}"
    end
  end
end

desc "build the source"
task :build => :configure do
  Dir.chdir ds_env.build_dir do
    sh "#{ds_env.make}" # VERBOSE=1
  end 
end

desc "run full test suite"
task :check => 'test:suite'

desc "build packages"
task :package => :build do
  Dir.chdir ds_env.build_dir do
    system("cpack #{ds_env.root_dir}")
    sh("dpkg --contents *.deb")
  end 
end

desc "rebuild tag file"
task :tags do
  FileUtils.rm "tags" if File.exists?("tags")
  FileUtils.rm "cscope.out" if File.exists?("tags")
  sh "ctags -R --exclude=debian,pkg,#{ds_env.build_dir}"
  sh "cscope -b #{ds_env.scopefiles.to_s}"
end

desc "clean and git status"
task :status => :clobber do
  sh "git status"
end

desc "tag and start edit session"
task :edit => [ :tags ] do
  sh "#{ds_env.editor} #{ds_env.editfiles.to_s}"
end

desc "run program"
task :run => :build do
  Dir.chdir ds_env.build_dir do
   system "#{ds_env.frontend} #{ds_env.run_arguments}"
  end 
end

# ========== debugging support ====================

namespace :test do
  desc "run ds_env.frontend program through valgrind"
  task :grind => 'build' do
    Dir.chdir ds_env.build_dir do
      system "valgrind --leak-check=full --show-reachable=yes #{ds_env.frontend} #{ds_env.run_arguments}"
    end
  end

  desc "run cucumber"
  task :cucumber => 'build' do
    Dir.chdir "#{ds_env.build_dir}/#{ds_env.features}" do
      sh "cucumber #{ds_env.root_dir}/#{ds_env.features}"
    end
  end

  desc "run all tests"
  task :suite => 'build' do
    Dir.chdir ds_env.build_dir do
      ENV["GTEST_COLOR"]="yes"
      system("#{ds_env.make} test")
    end 
  end
end

# ========== code coverage =======================
namespace :cov do

  desc "run the SUT"
  task :run => 'build' do
    output="#{ds_env.build_dir}/tests/unit/reports/"
    sh "#{ds_env.sut} --gtest_output=xml:#{output}"
  end

  desc "use LCOV for transformation (deprecated)"
  task :lcov => :run do
    sh "lcov --capture --directory #{ds_env.build_dir}/src --output-file #{ds_env.build_dir}/coverage.info"
    sh "genhtml #{ds_env.build_dir}/coverage.info --output-directory #{ds_env.build_dir}/lcov"
    sh "epiphany #{ds_env.build_dir}/lcov/index.html &"
end

  desc "check coverage in browser"
  task :html => :run do
    sh "#{ds_env.gcovr_bin} #{ds_env.gcovr_opt} --html --html-details -o #{ds_env.build_dir}/gcov.html"
    sh "epiphany #{ds_env.build_dir}/gcov.html &"
    puts "see: #{ds_env.build_dir}/gcov.html"
  end

  desc "export gtest coverage"
  task :gtest => :run do
    sh "#{ds_env.gcovr_bin} #{ds_env.gcovr_opt} --xml -o #{ds_env.build_dir}/coverage.xml"
  end

  desc "export cucumber coverage"
  task :features => 'build' do
    Dir.chdir "#{ds_env.build_dir}/#{ds_env.features}" do
      sh "cucumber -f json -o result.json -f junit -o reports #{ds_env.root_dir}/#{ds_env.features}"
    end
  end

  desc "export all coverages"
  task :all => [ :gtest, :features ]

  desc "export coverage for jenkins"
  task :text => :run do
    sh "#{ds_env.gcovr_bin} #{ds_env.gcovr_opt}"
  end
end

# ========== documentation and asset generation  =======================

namespace :doc do
  desc "show dependency graph"
  task :depgraph => :configure do
    Dir.chdir ds_env.build_dir do
      sh "cmake --graphviz=depdot #{ds_env.cmake_base_options} #{ds_env.cmake_options} #{ds_env.root_dir}"
      sh "dot -Tps < depdot >depdot.ps"
      sh "evince depdot.ps"
    end
  end
end


