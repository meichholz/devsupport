# this task bundle assumes
# - everything in *.ac and *.am
# - usage of "build-aux" and "m4"
# - no custom *.in (although basic care is taken to not clobber assets away)
# - inplace build in "src"
# - tests in "tests"
# - debian standard boilerplate, if packaging is requested
#
# Full debug build: rake clobber ds:test:on build

ds_tasks_for :ccommon

ds_configure(defaults: true) do |c|
  c.build_dir = Dir.pwd
  c.builddirs = [ c.sourcedir, 'lib', 'tests/unit' ]
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
  c.editfiles = FileList.new '**/Makefile.am', 'configure.ac'
  c.scopefiles = FileList.new "#{c.sourcedir}/**/*.c*", "#{c.sourcedir}/**/*.h"
  c.automakefiles = FileList.new '**/*.am'
end

task 'ds:conclude' do
  ds_configure(defaults: true) do |c|
    c.gcov_bin='gcov'
  end
  ds_ccommon_post_configure
end

# it is *extremely* important to leave the generated configure stuff during "rake clean"
# "rake clean" may remove just noise
CLOBBER.include 'configure', 'build-aux', 'autom4te*', 'aclocal.m4', 'm4'
CLOBBER.include 'config.status', 'config.log', 'configure'
CLOBBER.include File.join(ds_env.sourcedir, 'config.h.in')

if File.exists? 'Makefile.am'
  CLOBBER.include '**/Makefile.in', '**/Makefile'
end

file "configure" => ds_env.automakefiles + ["configure.ac", "m4"] do
  sh "autoreconf --install"
  sh "touch configure"
end

file "m4" do
  sh "mkdir m4"
  sh "cp #{ds_env.m4files} m4/" unless ds_env.m4files.nil?
end

desc "Configure with options: #{ds_env.configure_options}"
task :run_configure do
  sh "./configure #{ds_env.configure_options}"
end

file "Makefile" => [ "configure" ] do
  Rake::Task[:run_configure].invoke
end

desc "Rebuild configure script, needs configure present"
task :reconf => [ "configure" ]

desc "Run test suite"
task :check => [ :debugenv, "Makefile" ] do
  sh "make #{ds_env.make_options} VERBOSE=1 check"
end

desc "Remake with current configure, run clean check"
task :cleancheck => [ "configure", :tidyup ] do
  Rake::Task[:run_configure].invoke
  sh "make #{ds_env.make_options} check"
end

desc "Safely remove all generated stuff by make and rules"
task :tidyup do
  # do not let fail these tasks
  if File.exists? 'Makefile'
    `fakeroot make clean`
    `fakeroot make distclean`
  end
  Rake::Task[:clean].invoke
end

task :clobber => :tidyup

desc "Force a fast cleanup"
task :fastclobber do
  FileUtils.rm 'Makefile' if File.exists? 'Makefile'
  Rake::Task[:tidyup].invoke
end

desc "Bootstrap everything"
task :bootstrap => [ :clobber, "m4" ] do
  sh 'autoreconf --force --verbose --install'
  Rake::Task[:run_configure].invoke
  sh "make #{ds_env.make_options}"
  puts "\nNow: make check, or rake edit..."
end

desc "Build or rebuild debian package"
task :package => [ :tidyup, 'debian/rules' ] do
  system 'fakeroot ./debian/rules clean' if File.exists? 'debian/rules'
  sh "fakeroot ./debian/rules binary"
end

desc "Build for debugging"
task :build => [ 'clobber', 'debugenv', 'bootstrap', 'doc:build' ]



