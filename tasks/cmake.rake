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

@editor = "gvim -geometry 88x55+495-5" if @editor.nil?
@executable = FileList.new("src/#{@appname}")[0].to_s if @executable.nil?
@cmake_options = "-DCMAKE_INSTALL_PREFIX:PATH=/usr"  if @cmake_options.nil?
@concurrency = 4 if @concurrency.nil?
@make = "make -j#{@concurrency}" if @make.nil?
@root_dir = Dir.pwd if @root_dir.nil?
@build_dir = "build_dir" if @build_dir.nil?
@sut = "#{@build_dir}/tests/unit/test_main" if @sut.nil?
@frontend = "src/#{@appname}" if @frontend.nil?
@gcov_exclude = '^googletest' if @gcov_exclude.nil?

if @editfiles.nil?
  @editfiles = FileList.new([ # organize for speed nav
                            "**/CMakeLists.txt",
                            "src/*.c*", "README*"
                            ])
end

#puts "build_dir is: #{@build_dir}"
#puts "root_dir is: #{@root_dir}"
#exit 1

if @scopefiles.nil?
  @scopefiles = FileList.new(["src/**/*.c*", "src/**/*.h", "tests/**/*.c*", "tests/**/*.h", "tests/**/*.sh"])
end

task :default => :check

CLEAN.include("t", "tt*", "*~", "tags", "cscope.out" )
CLOBBER.include(@build_dir)

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
    sh "cucumber tests/features"
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
  @gcovr_opt="-r . --branches -u -e '#{@gcov_exclude}'"
  @gcovr_bin="devsupport/bin/gcovr"

  desc "run the SUT"
  task :run => 'build' do
    `#{@sut}`
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

  desc "export coverage for jenkins"
  task :cobertura => :run do
    sh "#{@gcovr_bin} #{@gcovr_opt} --xml -o #{@build_dir}/coverage.xml"
  end
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


