require "rake/clean"

# Dieses rake-taskset dient dazu, die Schritte rund um CMake
# und Debian abgedeckten Bereichs zu regeln.
# - Editing
# - Konfigurieren
# - Paketbau
# - Check

# abort "set umask to 022, please" if File.umask!=022

if @appname.nil?
  FileList.new(["**/CMakeLists.txt"]).each do |fitem|
    File.open fitem, "rb" do |f|
      f.each_line do |l|
        m = l.match(/^install\s*\(TARGETS (\w+) DESTINATION bin\)/)
        @appname = m[1] if m and @appname.nil?
      end
    end
  end
end

CLEAN.include("t", "tt*", "*~", "tags", "cscope.out" )
CLOBBER.include(@build_dir)

@editor = "gvim -geometry 88x55+495-5" if @editor.nil?
@executable = FileList.new("src/#{@appname}")[0].to_s if @executable.nil?
@cmake_options = "-DCMAKE_INSTALL_PREFIX:PATH=/usr"  if @cmake_options.nil?
@concurrency = 4 if @concurrency.nil?
@make = "make -j#{@concurrency}" if @make.nil?

# setup directories and layout
@root_dir = Dir.pwd if @root_dir.nil?
@build_dir = "build_dir" if @build_dir.nil?
@sut = "#{@build_dir}/tests/unit/test_main" if @sut.nil?
@frontend = "src/#{@appname}" if @frontend.nil?
@features="tests/features" unless @features

# setup gcov/gcovr support
@gcov_exclude = '^googletest' if @gcov_exclude.nil?

# setup GCC support, namely the best version
if @suitable_gcc_versions
  @suitable_gcc_versions.each do |ver|
    if system("gcc-#{ver} --version")
      puts "setting gcc-#{ver} as preferred compiler" if @debug_rake
      # CMAKE chooses the compiler through the environment
      ENV["CXX"] = "g++-#{ver}"
      ENV["CC"]  = "gcc-#{ver}"
      @gcc_version = ver
      break
    end
  end
end

# setup derived variables
@gcov_bin = @gcc_version ? "gcov-#{@gcc_version}" : "gcov"
@gcovr_opt = "--gcov-executable=#{@gcov_bin} -r . --branches -u -e '#{@gcov_exclude}'"
@gcovr_bin = "devsupport/bin/gcovr"

# setup default edit files set
if @editfiles.nil?
  @editfiles = FileList.new([ # organize for speed nav
                            "**/CMakeLists.txt",
                            "src/*.c*", "README*"
                            ])
end

if @debug_rake
  puts "build_dir is: #{@build_dir}"
  puts "root_dir is: #{@root_dir}"
end

if @scopefiles.nil?
  @scopefiles = FileList.new(["src/**/*.c*", "src/**/*.h", "tests/**/*.c*", "tests/**/*.h", "tests/**/*.sh"])
end

task :default => :check

desc "reconfigure the source"
task :reconf => [ :tidyup, :configure ]

desc "clean up build directory"
task :tidyup do
  FileUtils.rm_rf @build_dir if File.exists?(@build_dir)
end

desc "configure via cmake"
task :configure do
  unless File.exists? @build_dir
    FileUtils.mkdir @build_dir
    Dir.chdir @build_dir do
      sh "cmake #{@cmake_options} #{@root_dir}"
    end
  end
end

desc "build the source"
task :build => :configure do
  Dir.chdir @build_dir do
    sh "#{@make}" # VERBOSE=1
  end 
end

desc "run full test suite"
task :check => 'test:suite'

desc "build packages"
task :package => :build do
  Dir.chdir @build_dir do
    system("cpack #{@root_dir}")
    sh("dpkg --contents *.deb")
  end 
end

desc "rebuild tag file"
task :tags do
  FileUtils.rm "tags" if File.exists?("tags")
  FileUtils.rm "cscope.out" if File.exists?("tags")
  sh "ctags -R --exclude=debian,pkg,#{@build_dir}"
  sh "cscope -b #{@scopefiles.to_s}"
end

desc "clean and git status"
task :status => :clobber do
  sh "git status"
end

desc "tag and start edit session"
task :edit => [ :tags ] do
  sh "#{@editor} #{@editfiles.to_s}"
end

desc "run program"
task :run => :build do
  Dir.chdir @build_dir do
   system "#{@frontend} #{@run_arguments}"
  end 
end

# ========== debugging support ====================

namespace :test do
  desc "run @frontend program through valgrind"
  task :grind => 'build' do
    Dir.chdir @build_dir do
      system "valgrind --leak-check=full --show-reachable=yes #{@frontend} #{@run_arguments}"
    end
  end

  desc "run cucumber"
  task :cucumber => 'build' do
    Dir.chdir "#{@build_dir}/#{@features}" do
      sh "cucumber #{@root_dir}/#{@features}"
    end
  end

  desc "run all tests"
  task :suite => 'build' do
    Dir.chdir @build_dir do
      ENV["GTEST_COLOR"]="yes"
      system("#{@make} test")
    end 
  end
end

# ========== code coverage =======================
namespace :cov do

  desc "run the SUT"
  task :run => 'build' do
    output="#{@build_dir}/tests/unit/reports/"
    sh "#{@sut} --gtest_output=xml:#{output}"
  end

  desc "use LCOV for transformation (deprecated)"
  task :lcov => :run do
    sh "lcov --capture --directory #{@build_dir}/src --output-file #{@build_dir}/coverage.info"
    sh "genhtml #{@build_dir}/coverage.info --output-directory #{@build_dir}/lcov"
    sh "epiphany #{@build_dir}/lcov/index.html &"
end

  desc "check coverage in browser"
  task :html => :run do
    sh "#{@gcovr_bin} #{@gcovr_opt} --html --html-details -o #{@build_dir}/gcov.html"
    sh "epiphany #{@build_dir}/gcov.html &"
    puts "see: #{@build_dir}/gcov.html"
  end

  desc "export gtest coverage"
  task :gtest => :run do
    sh "#{@gcovr_bin} #{@gcovr_opt} --xml -o #{@build_dir}/coverage.xml"
  end

  desc "export cucumber coverage"
  task :features => 'build' do
    Dir.chdir "#{@build_dir}/#{@features}" do
      sh "cucumber -f json -o result.json -f junit -o reports #{@root_dir}/#{@features}"
    end
  end

  desc "export all coverages"
  task :all => [ :gtest, :features ]

  desc "export coverage for jenkins"
  task :text => :run do
    sh "#{@gcovr_bin} #{@gcovr_opt}"
  end
end

# ========== documentation and asset generation  =======================

namespace :doc do
  desc "show dependency graph"
  task :depgraph => :configure do
    Dir.chdir @build_dir do
      sh "cmake --graphviz=depdot #{@cmake_options} #{@root_dir}"
      sh "dot -Tps < depdot >depdot.ps"
      sh "evince depdot.ps"
    end
  end
end


