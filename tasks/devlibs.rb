# adding support for third party libraries
# * gtest
# * gmock
# * cpputest
# * gperftools
#
#@todo gtest configure-make depends on system python being version 2.x

ds_configure(defaults: true) do |c|
  c.devlib_sourcedir = '3rdparty'
  c.devlib_installdir = File.join(ds_env.root_dir, 'lib', 'aux')
  c.devlib_builddir = File.join(ds_env.root_dir, 'lib', 'build')
end

module Devsupport

  # This is a virtual base class implementing the common behaviour of library and
  # tool builders.
  class LibraryBuilder
    include ::Rake::DSL

    def initialize(options={})
      # this massive state is due to old procedural attempts.
      # @todo The global parameters should go to some shared instance, like the {BuildJanitor}
      # refactor at will ;-)
      @build_dir = Rake.options.devlib_builddir
      @install_dir = Rake.options.devlib_installdir
      @source_dir = Rake.options.devlib_sourcedir
      @name = options.fetch(:name, nil)
      @version = options.fetch(:version, nil)
      setup options
    end

    # get the source files, if needed
    # @return [void]
    def prepare
    end

    # build the library and install it
    # @return [void]
    def build
      raise "build not implemented in base class"
    end

    # clean up no longer used local artifacts after build, if suitable
    # @return [void]
    def cleanup
    end

    # clobber away, normally left out
    # @return [void]
    def clobber
    end

    protected

    # @return [String] the location of the 3rdparty-submodule subdirectory
    def repo_dir
      "#{@source_dir}/#{@name}-#{@version}/."
    end

    # @return [String] the specific build-directory. '''The naming is bad!'''
    def sandbox_dir
      "#{@build_dir}/#{@name}"
    end

    # hook: setup the builder object, post-constructor
    # @return [Void]
    def setup(options={}) # hook
    end
    
    # Just a helper to copy over (or construct link farm) for the local build directory
    def self.copy_sources(fromdir, todir)
      puts "ds: copy devlib source from #{fromdir} to #{todir}"
      FileUtils.cp_r fromdir, todir
    end
  end

  # The Janitor is a helper class to to the global stuff before and after the
  # specifical Builders. In fact it prepares the file system and purges all artifacts away.
  # @todo Probably it should keep the global parameters
  class BuildJanitor < LibraryBuilder
    def prepare
      FileUtils.mkdir @build_dir unless File.exists? @build_dir
      unless File.exists? @install_dir
        FileUtils.mkdir @install_dir
        FileUtils.touch "#{@install_dir}/.purgable"
      end
    end

    def clobber
      puts "purging devsupport build area"
      FileUtils.rm_rf @build_dir
      FileUtils.rm_rf @install_dir if File.exists? "#{@install_dir}/.purgable"
    end
  end

  class GoogleTestBuilder < LibraryBuilder

    def setup(options={})
      @opt_inside = options.fetch(:inside, false)
      @name = options.fetch(:name, :gtest)
      @version = '1.7.0'
    end

    def sandbox_dir
      if @opt_inside
        "#{@build_dir}/gmock/gtest"
      else
        "#{@build_dir}/#{@name}"
      end
    end

    def prepare
      self.class.copy_sources(repo_dir, sandbox_dir) unless File.exists? sandbox_dir or @opt_inside
    end

    # Build library and install it
    # @return [void]
    def build
      if File.exists? File.join(sandbox_dir, 'lib', '.libs', "lib#{@name}.a")
        puts "skipping: #{@name} built"
        return
      end
      Dir.chdir sandbox_dir do
        puts "now building #{@name}"
        sh "autoreconf --install"
        sh "./configure --enable-static --disable-shared --disable-dependency-tracking"
        sh "make" # NO install, see Gmock README
        # OK, we must fix the build result a bit to meet the expectations of
        # CPPUTEST and the SUT
#        Dir['lib/*.la', 'lib/.libs/*.la'].each do |lafile|
#          puts "INFO: Tidying away #{lafile} in #{sandbox_dir}"
#          FileUtils.rm_f lafile # remove problematic .la file versions
#        end
#        Dir['lib/.libs/*.a'].each do |afile|
#          puts "INFO: Symlinking #{afile} in #{sandbox_dir}"
#          FileUtils.ln_s afile, '.'
#        end
        # TODO: Manually install symlinks for libraries and headers
      end
    end

  end

  class CppUTestBuilder < LibraryBuilder
    def setup(options={})
      @name = :cpputest
      @version = '3.6'
      sandbox_dir = "#{@build_dir}/#{@name}"
    end

    def prepare
      self.class.copy_sources(repo_dir, sandbox_dir) unless File.exists? sandbox_dir
    end

    # @see [LibraryBuilder#build]
    # @return [void]
    def build
      if File.exists? File.join(@install_dir, 'lib', 'libCppUTestExt.a')
        puts "skipping: #{@name} built"
        return
      end
      Dir.chdir sandbox_dir do
        puts "now building #{@name}"
        ENV['GMOCK_HOME'] = File.join(@build_dir, 'gmock')
        sh "autoreconf --install"
        sh "./configure --prefix=#{@install_dir} --enable-static --disable-shared --disable-dependency-tracking --enable-silent-rules --enable-generate-map-file"
        sh "make"
        sh "make install"
      end
    end
  end
end

@devlib_builders = [
    Devsupport::GoogleTestBuilder.new,
    Devsupport::GoogleTestBuilder.new(name: :gmock),
    Devsupport::GoogleTestBuilder.new(inside: true), # needs shadow from gmock
    Devsupport::CppUTestBuilder.new,
]

namespace :build do
  desc 'Bootstrap 3rdparty libraries'
  task 'devlibs' do
    janitor = Devsupport::BuildJanitor.new
    janitor.prepare
    @devlib_builders.each do |builder|
      builder.prepare
      builder.build
      builder.cleanup
    end
    janitor.cleanup
  end

  task :purge do
    @devlib_builders.each do |builder|
      builder.clobber
    end
    Devsupport::BuildJanitor.new.clobber
  end

end
