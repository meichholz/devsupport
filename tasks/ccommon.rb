# this module extracts common aspects to our C projects.
# :cauto and :cmake should behave similar and - therefore - share common configuration.
# - testing frameworks
# - documentation and metrics frontends and locations
# - in place our build_dir building
# - C++ or C

namespace :ds do
  ds_tasks_for :common
end

ds_configure(defaults: true) do |c|
  c.debug_semaphore = 'dev_debug'
  c.sourcedir = 'src'
  c.sourcedirs = [ c.sourcedir, 'tests' ]
  c.cflags = '-g'
  c.debug_cflags = '-O0 -fPIC -ftest-coverage -fprofile-arcs'
  c.gcovr_exclude = '^gtest'
  c.gcovr_bin = 'devsupport/bin/gcovr'
  c.scopefiles = Dir['src/**/*.[ch]*', 'tests/unit/*.[ch]*'].join(' ')
  c.make_options = '--silent'
end


def ds_ccommon_post_configure
  ds_configure(defaults: true) do |c|
    c.gcovr_opt = "--gcov-executable=#{c.gcov_bin} -r . --branches -u -e '#{ds_env.gcovr_exclude}'"
    c.sut = "#{ds_env.build_dir}/tests/unit/test_main"
    c.builddirs.each do |tree|
      [ 'a', 'o', 'so', 'lo', 'la' ].each do |ext|
        CLOBBER.include "#{tree}/**/*.#{ext}"
      end
    end
    CLOBBER.include File.join(c.build_dir, 'tests/**/reports')
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

# emergency cleanup, if "make clean" fails too severely, should go to taskset
CLOBBER.include '**/*.gcda', '**/*.gcno',
  'coverage.xml',
  'doc'

# inhibit removal of testing libraries
CLEAN.exclude 'gtest/**/*', 'devsupport/**/*'
CLOBBER.exclude 'gtest/**/*', 'devsupport/**/*'

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

namespace :ci do
  desc 'CI full cycle'
  task :all => [ :build, :check, :cov ]

  desc 'Transform coverage report for cobertura'
  task :cov => ['cov:run', 'cov:xml', 'cov:html' ]

end


