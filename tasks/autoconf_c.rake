require "rake/clean"

# Dieses Taskset dient dazu, die Schritte AUSSERHALB des von Autoconf
# und Debian abgedeckten Bereichs zu regeln.
# - Editing
# - Abraeumen der von Autoconf erzeugten Dateien
# - Neuerzeugen des configure-Skriptes
# - Konfigurieren (ohne Debian)
#
# Version: 1.1 : bootstrap fixed. @configure_options neu.

if @appname.nil?
  File.open "src/Makefile.am", "rb" do |f|
    f.each_line do |l|
      m = l.match(/^bin_PROGRAMS\s*=\s*(\w+)/)
      @appname = m[1] if m
    end
  end
end

@editor = "gvim -geometry 88x55+495-5" if @editor.nil?
@executable = FileList.new("src/#{@appname}")[0].to_s if @executable.nil?
@frontend = "src/#{@appname}" if @frontend.nil?

if @editfiles.nil?
  @editfiles = FileList.new([ # organize for speed nav
                            "**/Makefile.am",
                            "src/*.c*", "tests/unit/*.c*",
                            ])
end

if @scopefiles.nil?
  @scopefiles = FileList.new(["**/*.c*", "**/*.h", "**/*.sh"])
end

@automake_am =FileList.new("**/*.am")

task :default => :check

CLEAN.include("t", "tt*", "*~" )
CLOBBER.include("configure", "build-aux",
                "autom4te*", "aclocal.m4",
                "cscope.out",
                "m4", "**/Makefile.in", "**/.deps")

file "configure" => @automake_am + ["configure.ac", "m4"] do
  sh "autoreconf --install"
  sh "touch configure"
end

file "m4" do
  sh "mkdir m4"
  sh "cp #{@m4files} m4/" unless @m4files.nil?
end

desc "run configure with options: #{@configure_options}"
task :run_configure do
  sh "./configure #{@configure_options}"
end

file "Makefile" => [ "configure" ] do
  Rake::Task[:run_configure].invoke
end

desc "rebuild configure script, needs an existing configure script"
task :reconf => [ "configure" ]

task :check => [ "Makefile" ] do
  sh "make check"
end

task :cleancheck => [ "configure" ] do
  sh "make distclean" if File.exists?("Makefile")
  Rake::Task[:run_configure].invoke
  sh "make check"
end

desc "SAFELY remove all generated stuff"
task :tidyup => :clean do
  sh "fakeroot ./debian/rules clean" if File.exists?("debian/rules")
  sh "make distclean" if File.exists?("Makefile")
end

task :clobber => :tidyup

desc "bootstrap everything"
task :bootstrap => [ :clobber, "m4" ] do
  sh "autoreconf --force --verbose --install"
  Rake::Task[:run_configure].invoke
  sh "make"
  puts "\nNow: make check, or rake edit..."
end

desc "build debian package"
task :package => :clean do
  sh "fakeroot ./debian/rules binary"
end

desc "rebuild tag file"
task :tags do
  FileUtils.rm "tags" if File.exists?("tags")
  FileUtils.rm "cscope.out" if File.exists?("tags")
  sh "ctags -R --exclude=debian,pkg"
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

desc "run app"
task :run do
  sh "#{@frontend}"
end

task :tell do
  puts "frontend: #{@frontend}"
end


