# linked in by layout/html/setup.rb

def init_dummy
  super
  begin
    generate_todo_index # would not work this way, investigate!
  rescue => e
    path = options.serializer.serialized_path(object)
    log.error "Macht 'Bumm' in #{path}"
    log.backtrace(e)
  end
end

def generate_todolist_list
  generate_todo_index
  @items = todolist_items
  @list_class = "class" # no own style sheet
  @list_title = "Undone"
  # note: list_type must match some things:
  # - the template file: <erbarg>_<@list_type>.erb
  # - the search list registration type
  @list_type = 'todolist'
  asset('todolist_list.html', erb(:full_list)) # contains something like a frame
end

def generate_todo_index
  @items = todolist_items
  # @todo we need SOME LAYOUT HERE and have ... nothing here
  asset('_todolist.html', erb(:todolist_index)) # contains something like a frame
end

def todolist_items
  items = Array.new
  add_todo_items items, "Fixme refs", :fixme
  add_todo_items items, "Todo refs", :todo
  add_todo_items items, "Think refs", :think
  items
end

def add_todo_items(items, header, tag1, tag2=nil)
  codos = todo_codo_list(tag1, tag2)
  return nil if codos.empty?
  items << { header: header, codos: codos }
end

#  @return [Array] all items that have tags with given name 
def todo_codo_list(*tags)
  YARD::Registry.all.select do |codo|
    rc = false
    tags.each do |tag|
      rc ||= codo.tag(tag)
    end
    rc
  end
end


