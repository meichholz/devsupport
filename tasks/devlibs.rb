# adding support for third party libraries
# * gtest
# * gmock
# * cpputest
# * gperftools
#
#@TODO
##Issues
# * gtest configure-make depends on system python being version 2.x
#

ds_configure(defaults: true) do |c|
  c.devlib_sourcedir = '3rdparty'
  c.devlib_installdir = File.join(ds_env.root_dir, 'lib', 'aux')
  c.devlib_builddir = File.join(ds_env.root_dir, 'lib', 'build')
end

module Devsupport
  class LibraryBuilder
    include ::Rake::DSL

    def initialize
      @build_dir = Rake.options.devlib_builddir
      @install_dir = Rake.options.devlib_installdir
      @source_dir = Rake.options.devlib_sourcedir
    end

    # @returns [void]
    def build_cpputest(version)
      name = :cpputest
      todir = "#{@build_dir}/#{name}"
      copy_source_tree(name, version, todir) unless File.exists? todir
      if File.exists? File.join(@install_dir, 'lib', 'libCppUTestExt.a')
        puts "skipping: #{name} built"
        return
      end
      Dir.chdir todir do
        puts "now building #{name}"
        ENV['GMOCK_HOME']=File.join(@build_dir, 'gmock')
        sh "autoreconf --install"
        sh "./configure --prefix=#{@install_dir} --enable-static --disable-shared --disable-dependency-tracking --enable-silent-rules --enable-generate-map-file"
        sh "make"
        sh "make install"
      end
    end
    # @returns [void]
    def build_googletest(name, version, opt={} )
      is_inside = opt.fetch(:inside, false)
      if is_inside
        todir = "#{@build_dir}/gmock/#{name}"
      else
        todir = "#{@build_dir}/#{name}"
        copy_source_tree(name, version, todir) unless File.exists? todir
      end
      if File.exists? File.join(todir, 'lib', '.libs', "lib#{name}.a")
        puts "skipping: #{name} built"
        return
      end
      Dir.chdir todir do
        puts "now building #{name}"
        sh "autoreconf --install"
        sh "./configure --enable-static --disable-shared --disable-dependency-tracking"
        sh "make" # NO install, see Gmock README
        Dir['lib/*.la', 'lib/.libs/*.la'].each do |lafile|
          puts "INFO: Tidying away #{lafile} in #{todir}"
          FileUtils.rm_f lafile # remove problematic .la file versions
        end
        Dir['lib/.libs/*.a'].each do |afile|
          puts "INFO: Symlinking #{afile} in #{todir}"
          FileUtils.ln_s afile, '.'
        end
        # TODO: Manually install symlinks for libraries and headers
      end
    end

    def copy_source_tree(name, version, todir)
      fromdir = "#{@source_dir}/#{name}-#{version}/."
      puts "ds: copy devlib source from #{fromdir} to #{todir}"
      FileUtils.cp_r fromdir, todir
    end

    def prepare
      FileUtils.mkdir @build_dir unless File.exists? @build_dir
      unless File.exists? @install_dir
        FileUtils.mkdir @install_dir
        FileUtils.touch "#{@install_dir}/.purgable"
      end
    end

    def purge
      puts "purging devsupport build area"
      FileUtils.rm_rf @build_dir
      FileUtils.rm_rf @install_dir if File.exists? "#{@install_dir}/.purgable"
    end

  end
end

namespace :build do
  desc 'Bootstrap 3rdparty libraries'
  task 'devlibs' do
    builder = Devsupport::LibraryBuilder.new
    builder.prepare
    builder.build_googletest :gmock, '1.7.0'
    builder.build_googletest :gtest, '1.7.0'
    builder.build_googletest :gtest, '1.7.0', inside: true
    builder.build_cpputest '3.6'
  end

  task :purge do
    builder = Devsupport::LibraryBuilder.new
    builder.purge
  end

end
