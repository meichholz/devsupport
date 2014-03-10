ds_tasks_for :common

# this task bundle assumes
# - everything in *.ac and *.am
# - usage of "build-aux" and "m4"
# - no custom *.in (although basic care is taken to not clobber assets away)
# - inplace build in "src"
# - tests in "tests"
# - debian standard boilerplate, if packaging is requested
ds_configure(defaults: true) do |c|
  c.sourcedir = "src"
  # guess appname and executable default for trivial cases
  appname = nil
  amfiles = Dir["#{c.sourcedir}/**/Makefile.am"]
  amfiles.each do |amfile|
    if File.exists? amfile
      # puts "INFO: checking #{amfile}"
      File.open(amfile,"rb") do |f|
        f.each_line do |l|
          m = l.match(/^s?bin_PROGRAMS\s*=\s*(\w+)/)
          appname ||= m[1] if m
        end
      end
    end
  end
  c.appname = appname
  c.executable = FileList.new("#{c.sourcedir}/#{c.appname}")[0].to_s
  c.frontend = "#{c.sourcedir}/#{c.appname}"
  c.editfiles = FileList.new "**/Makefile.am",
                            "#{c.sourcedir}/*.c*",
                            "tests/unit/*.c*"
  c.scopefiles = FileList.new "**/*.c*", "**/*.h", "**/*.sh"
  c.automake_am = FileList.new("**/*.am")
end

task :default => :check

CLOBBER.include "configure"
CLEAN.include "build-aux", "autom4te*", "aclocal.m4", "m4"
CLEAN.include "cscope.out", "doxygen", "sloc.sc"
CLEAN.include "**/.deps"
CLOBBER.include("**/Makefile.in") if File.exists? 'Makefile.am'

file "configure" => ds_env.automake_am + ["configure.ac", "m4"] do
  sh "autoreconf --install"
  sh "touch configure"
end

file "m4" do
  sh "mkdir m4"
  sh "cp #{ds_env.m4files} m4/" unless ds_env.m4files.nil?
end

desc "run configure with options: #{ds_env.configure_options}"
task :run_configure do
  sh "./configure #{ds_env.configure_options}"
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

desc "run app"
task :run do
  sh "#{ds_env.frontend}"
end

task :tell do
  puts "frontend: #{ds_env.frontend}"
end

namespace :doc do

  desc "build all documentation"
  task :build do
    sh "sloccount --duplicates --details --wide Rakefile #{ds_env.sourcedir} >sloc.sc"
    sh "rm -rf doxygen || true"
    sh "doxygen"
  end

  desc "view doc with browser"
  task :view => [ :build ] do
    system "#{ds_env.browser} doxygen/html/index.html"
  end

end

namespace :ci do
  desc "basic build: bootstrap, package, build doc"
  task :base => [ 'bootstrap', 'package', 'doc:build', 'check' ]
end

