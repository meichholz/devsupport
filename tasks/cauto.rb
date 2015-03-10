# this task bundle assumes
# - everything in *.ac and *.am
# - usage of "build-aux" and "m4"
# - no custom *.in (although basic care is taken to not clobber assets away)
# - inplace build in "src"
# - tests in "tests"
# - debian standard boilerplate, if packaging is requested
#
# Full debug build: rake clobber ds:test:on build
#
# @TODO cauto darf Makefile.in in "gtest" nicht abräumen.
# @TODO "check" löst keinen gecheckten Voll-Rebuild aus (Abhängigkeit)
#

namespace :ds do
  ds_tasks_for :common
end

ds_configure(defaults: true) do |c|
  c.debug_semaphore = 'dev_debug'
  c.build_dir = Dir.pwd
  c.sourcedir = 'src'
  c.sourcedirs = [ c.sourcedir, 'tests' ]
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
  c.make_options = ""
  c.appname = appname
  c.executable = FileList.new("#{c.sourcedir}/#{c.appname}")[0].to_s
  c.frontend = "#{c.sourcedir}/#{c.appname}"
  c.editfiles = FileList.new '**/Makefile.am', 'configure.ac'
  c.scopefiles = FileList.new '**/*.c*', '**/*.h', '**/*.sh'
  c.automakefiles = FileList.new '**/*.am'
  c.cflags = '-g'
  c.debug_cflags = '-O0 -fPIC -ftest-coverage -fprofile-arcs'
  c.gcovr_exclude = '^gtest'
  c.gcovr_bin = "devsupport/bin/gcovr"
end

def ds_post_configure
  ds_configure(defaults: true) do |c|
    version = nil
    c.make = "#{ds_env.make_bin} -j#{ds_env.concurrency}"
    c.gcov_bin = version ? "gcov-#{version}" : "gcov"
    c.gcovr_opt = "--gcov-executable=#{c.gcov_bin} -r . --branches -u -e '#{ds_env.gcovr_exclude}'"
    c.sut = "#{ds_env.build_dir}/tests/unit/test_main"
  end
end

task :default => :check

@debug_mode = File.exists?(ds_env.debug_semaphore) || ENV['DEV_DEBUGMODE']

desc 'Use environment for debugging (internal, chainable)'
task :debugenv do
  cflags = ds_env.cflags
  cflags << " " << ds_env.debug_cflags if @debug_mode
  ENV['CFLAGS'] = cflags
  ENV['CXXFLAGS'] = cflags
end

# it is *extremely* important to leave the generated configure stuff during "rake clean"
# "rake clean" may remove just noise
CLEAN.include 'cscope.out', 'doxygen', 'sloc.sc'
CLEAN.include "**/.deps"
CLOBBER.include 'configure', 'build-aux', 'autom4te*', 'aclocal.m4', 'm4'

if File.exists? 'Makefile.am'
  CLOBBER.include '**/Makefile.in', '**/Makefile'
end

CLOBBER.include '**/*.gcda', '**/*.gcno',
  'coverage.xml',
  'doc',
  'config.status',
  'config.log',
  'configure',
  'tests/**/reports'

CLOBBER.include File.join(ds_env.sourcedir, 'config.h.in')
# emergency cleanup, if "make clean" fails too severely, should go to taskset
ds_env.builddirs.each do |tree|
  [ 'a', 'o', 'so', 'lo', 'la' ].each do |ext|
    CLOBBER.include "#{tree}/**/*.#{ext}"
  end
end

CLEAN.exclude 'gtest/**/*'
CLOBBER.exclude 'gtest/**/*'


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

desc "Bootstrap everything"
task :bootstrap => [ :clobber, "m4" ] do
  sh 'autoreconf --force --verbose --install'
  Rake::Task[:run_configure].invoke
  sh 'make'
  puts "\nNow: make check, or rake edit..."
end

desc "Build or rebuild debian package"
task :package => [ :tidyup, 'debian/rules' ] do
  system 'fakeroot ./debian/rules clean' if File.exists? 'debian/rules'
  sh "fakeroot ./debian/rules binary"
end

desc "Rebuild tag file"
task :tags do
  FileUtils.rm "tags" if File.exists?("tags")
  FileUtils.rm "cscope.out" if File.exists?("tags")
  sh "ctags -R --exclude=debian,pkg"
  sh "cscope -b #{ds_env.scopefiles.to_s}"
end

desc "Cleanup and git status"
task :status => :clobber do
  sh "git status"
end

desc "Start clean edit session"
task :edit => [ :tags ] do
  sh "#{ds_env.editor} #{ds_env.editfiles.to_s}"
end

desc "Run app frontend: #{ds_env.frontend}"
task :run do
  sh "#{ds_env.frontend}"
end

file 'doc' do
  FileUtils.mkdir "doc" unless File.exists? "doc"
end

namespace :doc do

  desc "Build all documentation"
  task :build do
    sh "sloccount --duplicates --details --wide Rakefile #{ds_env.sourcedirs.join(' ')} >sloc.sc"
    sh "rm -rf doxygen || true"
    sh "doxygen"
  end

  desc "View doc with browser"
  task :view => [ :build ] do
    system "#{ds_env.browser} doxygen/html/index.html"
  end

end

namespace :cov do

  desc "run the SUT, producing coverage data"
  task :run => 'check' do
    output="#{ds_env.build_dir}/tests/unit/reports/"
    sh "#{ds_env.sut} --gtest_output=xml:#{output}"
  end

  desc "Generate HTML coverage report"
  task :html => [ :run, 'doc' ] do
    sh "#{ds_env.gcovr_bin} #{ds_env.gcovr_opt} -r . --branches -u --html -o doc/gcov.html"
  end

  desc "Preview coverage"
  task :view => :html do
    sh "#{ds_env.browser} doc/gcov.html &"
  end

  desc "Produce XML coverage report"
  task :xml => 'doc' do
    sh "#{ds_env.gcovr_bin} #{ds_env.gcovr_opt} -r . --branches -u --xml -o doc/coverage.xml"
  end
end

desc "Build for debugging"
task :build => [ 'clobber', 'debugenv', 'bootstrap', 'doc:build' ]

namespace :ci do
  desc 'CI full cycle'
  task :all => [ :build, :check, :cov ]

  desc 'Transform coverage report for cobertura'
  task :cov => ['cov:run', 'cov:xml' ]

end

namespace :ds do
  namespace :test do

    desc "Switch debug/test mode on"
    task :on do
      FileUtils.touch ds_env.debug_semaphore unless File.exists? ds_env.debug_semaphore
    end

    desc "Switch debug/test mode off"
    task :off do
      FileUtils.rm ds_env.debug_semaphore if File.exists? ds_env.debug_semaphore
    end
  end
end

