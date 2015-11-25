# this module extracts common aspects to our C projects.
# :cauto and :cmake should behave similar and - therefore - share common configuration.
# - testing frameworks
# - documentation and metrics frontends and locations
# - in place our build_dir building
# - C++ or C

ENV['GTEST_COLOR'] = 'auto'
ENV['LANG'] = 'C'

namespace :ds do
  ds_tasks_for :common
end

ds_configure(defaults: true) do |c|
  c.root_dir = Dir.pwd
  c.debug_semaphore = "#{Dir.pwd}/dev_debug" # debug the SUT, not the rake framework itself :-)
  # preset standard file layout
  c.sourcedir = 'src'
  c.sourcedirs = [ c.sourcedir, 'tests' ]
  c.features = 'tests/features'
  c.scopefiles = Dir['src/**/*.[ch]*', 'tests/unit/*.[ch]*'].join(' ')
  # todo: run group of testprograms, inferred from config
  c.frontend = c.executable
  # preset making options and tooling
  c.concurrency = 4 # used on parallel make support
  c.cflags = '-g'
  c.gcc_versions = nil
  c.gcovr_exclude = '^3rdparty'
  c.gcovr_bin = 'devsupport/bin/gcovr'
  c.debug_cflags = '-O0 -fPIC -ftest-coverage -fprofile-arcs'
  c.make_bin = 'make'
  c.make_options = ''
end

def ds_debug_mode?
  File.exists?(ds_env.debug_semaphore) || ENV['DEV_DEBUGMODE']
end

def ds_ccommon_post_configure
  @debug_mode = ds_debug_mode?
  version = nil
  # find suitable compiler version, needed for CMAKE and C++11
  if ds_env.gcc_versions
    ds_env.gcc_versions.each do |ver|
      if system("g++-#{ver} --version >/dev/null 2>&1")
        puts "DEBUG: setting gcc-#{ver} as preferred compiler" if ds_env.debug_rake
        version = ver
        break
      end
    end
  end
  # make results available to CMAKE
  if version
    ENV["CXX"] = "g++-#{version}"
    ENV["CC"]  = "gcc-#{version}"
    ENV["GCOV"]  = "gcov-#{version}"
  end
  # abstract away some other glue settings as kind of macros
  ds_configure(defaults: true) do |c|
    c.ci_suite_arguments = "--gtest-options=xml:#{ds_env.build_dir}/tests/unit/reports/"
    c.make = "#{ds_env.make_bin} -j#{ds_env.concurrency} #{ds_env.make_options}"
    c.gcov_bin = version ? "gcov-#{version}" : "gcov"
    c.gcovr_opt = "--gcov-executable=#{c.gcov_bin} -r . --branches -u -e '#{ds_env.gcovr_exclude}'"
    c.sut = "#{ds_env.build_dir}/tests/unit/test_main"
    c.builddirs = [ ds_env.build_dir ]
  end
  ds_env.builddirs.each do |tree|
      CLOBBER.include "#{tree}/tests/**/reports"
      [ 'deps', 'gcda', 'gcno', 'a', 'o', 'so', 'lo', 'la' ].each do |ext|
        CLOBBER.include "#{tree}/**/*.#{ext}"
      end
    end
end

task :default => :check

desc 'Use environment for debugging (internal, chainable)'
task :debugenv do
  cflags = ds_env.cflags
  cflags << " " << ds_env.debug_cflags if ds_debug_mode?
  ENV['CFLAGS'] = cflags
  ENV['CXXFLAGS'] = cflags
end

# it is *extremely* important to leave the generated configure stuff during "rake clean"
# "rake clean" may remove just noise
CLEAN.include 'cscope.out', 'doxygen', 'sloc.sc'

# emergency cleanup, if "make clean" fails too severely, should go to taskset
CLOBBER.include 'coverage.xml', 'doc'

# inhibit removal of testing libraries
[ 'lib', '3rdparty', 'devsupport', 'googletest', 'gtest' ].each do |tree|
  CLEAN.exclude "#{tree}/**/*"
  CLOBBER.exclude "#{tree}/**/*"
end


desc "Rebuild tag file"
task :tags do
  FileUtils.rm "tags" if File.exists?("tags")
  FileUtils.rm "cscope.out" if File.exists?("tags")
  sh "ctags -R --exclude=debian,pkg,#{ds_env.build_dir}"
  sh "cscope -b #{ds_env.scopefiles.to_s}"
end

desc "Clean and git status"
task :status => :clobber do
  sh "git status"
end

desc "Tag and start edit session"
task :edit => [ :tags ] do
  sh "#{ds_env.editor} #{ds_env.editfiles.to_s}"
end

desc "Run app frontend: #{ds_env.frontend}"
task :run => :build do
  Dir.chdir ds_env.build_dir do
    system "#{ds_env.frontend} #{ds_env.run_arguments}"
  end 
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

  desc "Run the SUT, producing coverage data"
  task :run => 'check' do
    ENV['GTEST_COLOR'] = 'no'
    sh "#{ds_env.sut} #{ds_env.ci_suite_arguments}"
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

namespace :suck do
  desc 'Pull in test framework sources from web (deprecated)'
  task :frameworks => [ :googletest ]

  desc 'Pull google test sources'
  task :googletest do
    chdir '3rdparty' do
      Dir['g*-1*'].each do |treename|
        puts "removing #{treename}"
        FileUtils.rm_rf treename
      end
      [ 'test', 'mock' ].each do |atype|
        zipfile = "g#{atype}-1.7.0.zip"
        sh "wget https://google#{atype}.googlecode.com/files/#{zipfile}"
        puts "unpacking #{zipfile}"
        sh "unzip #{zipfile}"
        FileUtils.rm zipfile
      end
    end
  end
end

namespace :ci do
  desc 'CI full cycle'
  task :all => [ :build, :check, :cov ]

  desc 'Transform coverage report for cobertura'
  task :cov => ['cov:run', 'cov:xml', 'cov:html' ]

end

namespace :test do
  desc "Run ds_env.frontend program through valgrind"
  task :grind => 'build' do
    Dir.chdir ds_env.build_dir do
      system "valgrind --leak-check=full --show-reachable=yes #{ds_env.frontend} #{ds_env.run_arguments}"
    end
  end

  desc "Run feature tests with Cucumber"
  task :cucumber => 'build' do
    Dir.chdir "#{ds_env.build_dir}/#{ds_env.features}" do
      sh "cucumber #{ds_env.root_dir}/#{ds_env.features}"
    end
  end

  desc "Run common test suite"
  task :suite => 'build' do
    Dir.chdir ds_env.build_dir do
      system("#{ds_env.make} test")
    end 
  end
end

