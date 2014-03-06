load File.join(File.dirname(__FILE__), 'common.rake')

# Dieses Taskset dient dazu, die Schritte AUSSERHALB des von Autoconf
# und Debian abgedeckten Bereichs zu regeln.
# - Editing
# - Abraeumen der von Autoconf erzeugten Dateien
# - Neuerzeugen des configure-Skriptes
# - Konfigurieren (ohne Debian)
#
# Version: 5.3.2013
#
# Specific overridables:
# @sourcedir
# @appname
# @amfiles
#
# Generic overridables:
# @executable
# @frontend
# @editfiles
#
@sourcedir ||= "src"
@amfiles  ||= [ "#{@sourcedir}/Makefile.am" ]

@amfiles.each do |amfile|
  if File.exists? amfile
    File.open(amfile,"rb") do |f|
      f.each_line do |l|
        m = l.match(/^bin_PROGRAMS\s*=\s*(\w+)/)
        @appname ||= m[1] if m
      end
    end
  end
end

# specific settings
@executable ||= FileList.new("#{@sourcedir}/#{@appname}")[0].to_s
@frontend ||= "#{@sourcedir}/#{@appname}"

@editfiles ||= FileList.new "**/Makefile.am",
                            "#{@sourcedir}/*.c*", "tests/unit/*.c*"

@scopefiles ||= FileList.new "**/*.c*", "**/*.h", "**/*.sh"

@automake_am = FileList.new("**/*.am")

task :default => :check

CLOBBER.include "configure"
CLEAN.include "build-aux", "autom4te*", "aclocal.m4", "m4"
CLEAN.include "cscope.out", "doxygen", "sloc.sc"
CLEAN.include "**/.deps"
CLOBBER.include("**/Makefile.in") if File.exists? 'Makefile.am'

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
task :tidyup do
  # do not let fail these tasks
  system "fakeroot ./debian/rules clean" if File.exists?("debian/rules")
  system "fakeroot make distclean" if File.exists?("Makefile")
  Rake::Task[:clean].invoke
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

namespace :doc do

  desc "build all documentation"
  task :build do
    sh "sloccount --duplicates --details --wide Rakefile #{@sourcedir} >sloc.sc"
    sh "rm -rf doxygen || true"
    sh "doxygen"
  end

  desc "view doc with browser"
  task :view => [ :build ] do
    system "#{@browser} doxygen/html/index.html"
  end

end

namespace :ci do
  desc "basic build: bootstrap, package, build doc"
  task :base => [ 'bootstrap', 'package', 'doc:build', 'check' ]
end


