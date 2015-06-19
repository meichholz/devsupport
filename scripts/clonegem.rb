require 'fileutils'

def panic(reason)
  STDERR.puts "FATAL: #{reason}"
  exit 1
end

def verbalize(level, s)
  puts s
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

  def guess_dirname(dir)
    File.basename(dir)
  end

  def guess_modulename(dir)
    File.basename(dir).capitalize
  end

end

class GemCloner

  def initialize(src, dest)
    @src = src
    @dest = dest
  end

  def check
    verbalize :info, "using: #{@src.path} as template"
    panic("#{src.dir} not existing") unless Dir.exist?(@src.path)
    files = Dir['.git', '*']
    return true if files.empty?
    false
  end

  def copy
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

  def patch
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


end

src = Project.new(path: File.join(ENV['HOME'], 'projects/gems/reco'),
                 )

dest = Project.new(path: Dir.pwd)

cloner = GemCloner.new(src, dest)

cloner.check || panic('project not pristine')
cloner.copy
cloner.patch



