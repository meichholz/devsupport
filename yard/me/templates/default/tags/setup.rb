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
  return unless object.has_tag?(:todolist)
  STDERR.puts "\nDEBUG: generating todolist for single object\n"
  @items = Array.new
  @items << { header: "Fixmes", items: todo_item_list(:fixme, :FIXME), }
  @items << { header: "Todos", items: todo_item_list(:todo, :TODO), }
  @items << { header: "Thinks about it", items: todo_item_list(:think, :THINK), }
  out = erb(:local_todolist)
  @items = nil
  out
end

#  @return [Array] all items that have tags with given name 
def todo_item_list(*tags)
  YARD::Registry.all.select do |codo|
    rc = false
    tags.each do |tag|
      rc ||= codo.tag(tag)
    end
    rc
  end
end

def generic_tag(name1, name2, opts = {})
  return unless object.has_tag?(name1) or object.has_tag?(name2)
  STDERR.puts "\nDEBUG: gentag '#{name1}'\n"
  # @no_names = true if opts[:no_names]
  # @no_types = true if opts[:no_types]
  @tags = Array.new
  @tags << object.tags(name1)
  @tags << object.tags(name2) if name2 and name2!=name1
  p @tags
  @tags.flatten!
  @name = name1
  @label = "Not done yet (#{name1})"
  out = erb('todo_tagged')
  @no_names, @no_types = nil, nil
  out
end
