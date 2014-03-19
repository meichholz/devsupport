# see:
# https://github.com/visfleet/yard-rest-plugin/blob/master/templates/rest/tags/setup.rb
#
def init
  super
  list = [:fixme, :todo, :think, :todolist]
  sections :index, list
end

def fixme
  generic_tag :fixme, :FIXME
end

def todo
  generic_tag :todo, :TODO
end

def think
  generic_tag :think, :THINK
end

def todolist
  generic_tag :todolist, nil
end

def generic_tag(name1, name2, opts = {})
  return unless object.has_tag?(name1) or object.has_tag?(name2)
  STDERR.puts "\nDEBUG: running for #{name1}\n"
  # @no_names = true if opts[:no_names]
  # @no_types = true if opts[:no_types]
  @tags = Array.new
  @tags << object.tags(name1)
  @tags << object.tags(name2) if name2 and name2!=name1
  @tags.flatten!
  @name = name1
  out = erb('generic_tag')
  @no_names, @no_types = nil, nil
  out
end
