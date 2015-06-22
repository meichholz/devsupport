require 'fileutils'

class Options
  @verbose = true
  class << self
    attr_accessor :verbose
  end
end

def panic(reason)
  STDERR.puts "FATAL: #{reason}"
  exit 1
end

def verbalize(level, s)
  puts "#{level}: #{s}" if Options::verbose
end

# Project collects characteristics of the source and destination projects
class Project

  attr_reader :path, :dirname, :modulename, :style

  def initialize(opt={})
    @path = opt.fetch(:path, nil)
    @dirname = opt.fetch(:dirname, guess_dirname(@path))
    @modulename = opt.fetch(:modulename, guess_modulename(@path))
    @style = :hoe
  end

  def devsupport_url
    # @todo may be inferred from source and cloned later
    'ssh://giles.bugslayer.de/srv/git/projects/devsupport'
  end

  def guess_dirname(dir)
    File.basename(dir)
  end

  def guess_modulename(dir)
    File.basename(dir).capitalize
  end

end

class GemCloner

  def initialize(src, dest, opt={})
    @src = src
    @dest = dest
    @opt_create = opt.fetch(:create, false)
  end

  def inside_destination
    dir = @dest.path
    panic "cannot chdir to `#{dir}'" unless Dir.exist?(dir)
    Dir.chdir dir do
      yield
    end
  end

  def create!
    destdir = @dest.path
    verbalize :info, "check and create `#{destdir}'"
    return false if Dir.exist? destdir
    system("git init #{@dest.dirname}")
    inside_destination do
      system("git submodule add #{@src.devsupport_url}")
    end
    true
  end

  def check
    verbalize :info, "using: #{@src.path} as template"
    panic("#{src.dir} not existing") unless Dir.exist?(@src.path)
    files = Dir['.git', '*']
    return true if files.empty?
    false
  end

  def copy!
    srcdir = @src.path
    verbalize :info, "copying over: #{srcdir}"
    files = Array.new
    Dir.chdir srcdir do
      files = Dir['bin/*', 'lib/**/*.rb', '*.md', 'spec/**/*.rb', 'features/**/*.rb']
      [ 'Manifest.txt', 'Rakefile', 'local.vim', '.projections.json'].each do |file|
        files << file
      end
    end
    @allfiles = Array.new
    files.each do |file|
      fromfile = File.join(srcdir, file)
      tofile = file.gsub(@src.dirname, @dest.dirname)
      path = File.dirname(tofile)
      verbalize :info, "getting: #{tofile}"
      FileUtils.mkdir_p path unless Dir.exist?(path)
      FileUtils.cp fromfile, tofile
      @allfiles << tofile
    end
  end

  def patch!
    # TODO: determine old and new NameSpaces :-)
    # TODO: find all files and run them through a filter
    # TODO: patch all path references (oldproject, newproject)
    # TODO: patch all NameSpace references
    @allfiles.each do |file|
      patch_file file
    end
  end

  def patch_file(file)
    verbalize :info, "patching #{file}"
  end

  def run!
    if @opt_create
      create! || panic('cannot create empty project frame')
    else
      inside_destination do
        check || panic('project not pristine')
      end
    end
    inside_destination do
      copy!
      patch!
    end
  end

end

# @todo: take from ARGV
@newpro_dir = 'guiframe'
@newpro_module = 'GuiFrame'

src = Project.new(path: File.join(ENV['HOME'], 'projects', 'gems', 'reco'),
                 )
dest = Project.new(path: File.join(Dir.pwd, @newpro_dir),
                   module_name: @newpro_module,
                  )

cloner = GemCloner.new(src, dest,
                      create: true,
                      )
cloner.run!




