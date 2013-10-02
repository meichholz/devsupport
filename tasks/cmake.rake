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
@frontend = "src/#{@appname}" if @frontend.nil?
@cmake_options = "-DCMAKE_INSTALL_PREFIX:PATH=/usr"  if @cmake_options
@concurrency = 4 if @concurrency.nil?
@make = "make -j#{@concurrency}" if @make.nil?

if @editfiles.nil?
  @editfiles = FileList.new([ # organize for speed nav
                            "**/CMakeLists.txt",
                            "src/*.c*", "README*"
                            ])
end

if @scopefiles.nil?
  @scopefiles = FileList.new(["src/**/*.c*", "src/**/*.h", "tests/**/*.c*", "tests/**/*.h", "tests/**/*.sh"])
end

@build_dir="build_dir"
@root_dir=Dir.pwd

task :default => :check

CLEAN.include("t", "tt*", "*~", "tags", "cscope.out" )
CLOBBER.include(@build_dir)

desc "reconfigure the source"
task :reconf => [ :tidyup, :build ]

desc "clean up build directory"
task :tidyup do
  FileUtils.rm_rf @build_dir if File.exists?(@build_dir)
end

file @build_dir do
  FileUtils.mkdir @build_dir unless File.exists?(@build_dir)
  Dir.chdir @build_dir do
    sh "cmake #{@cmake_options} #{@root_dir}"
  end
end

desc "show dependency graph"
task :graph => [ @build_dir ] do
  Dir.chdir @build_dir do
    sh "cmake --graphviz=depdot #{@cmake_options} #{@root_dir}"
    sh "dot -Tps < depdot >depdot.ps"
    sh "evince depdot.ps"
  end
end

desc "build the source"
task :build => [ @build_dir ] do
  Dir.chdir @build_dir do
    sh "#{@make}" # VERBOSE=1
  end 
end

desc "run test suite"
task :check => :build do
  Dir.chdir @build_dir do
    ENV["GTEST_COLOR"]="yes"
    system("#{@make} test")
  end 
end

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

desc "run program through valgrind"
task :grindrun => :build do
  Dir.chdir @build_dir do
    system "valgrind --leak-check=full --show-reachable=yes #{@frontend} #{@run_arguments}"
  end
end

