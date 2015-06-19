require 'fileutils'

def panic(reason)
  STDERR.puts "FATAL: #{reason}"
  exit 1
end

def guess_project(directory)
  File.basename(directory)
end

class GemCloner

  def initialize(opt={})
    @from_dir = opt.fetch(:from_dir, nil)
    @from_project = guess_project(@from_dir)
    @project = guess_project(Dir.pwd)
  end

  def check
    puts "using: #{@from_dir} as template"
    panic('need from_dir') unless Dir.exist?(@from_dir)
    # @todo check for pristinity
    files = Dir['.git', '*']
    return true if files.empty?
    false
  end

  def copy
    puts "copying over: #{@from_dir}"
    files = Array.new
    Dir.chdir @from_dir do
      files = Dir['bin/*', 'lib/**/*.rb', '*.md', 'spec/**/*.rb', 'features/**/*.rb']
      [ 'Rakefile', 'local.vim', '.projections.json'].each do |file|
        files << file
      end
    end
    files.each do |file|
      fromfile = File.join(@from_dir, file)
      tofile = file.gsub(@from_project, @project)
      path = File.dirname(tofile)
      puts "getting: #{tofile}"
      FileUtils.mkdir_p path unless Dir.exist?(path)
      FileUtils.cp fromfile, tofile
    end
  end

  def patch
    # TODO: determine old and new NameSpaces :-)
    # TODO: find all files and run them through a filter
    # TODO: patch all path references (oldproject, newproject)
    # TODO: patch all NameSpace references
  end

end

from_dir = File.join(ENV['HOME'],'projects/gems/reco')

cloner = GemCloner.new(from_dir: from_dir,
                      )

cloner.check || panic('project not pristine enough')
cloner.copy
cloner.patch



