
def init
  super
  begin
    serialize_todolist_index
  rescue => e
    path = options.serializer.serialized_path(options.object)
    log.error "Exception occurred while generating soliton file '#{path}'"
    log.backtrace(e)
  end
end

def serialize_todolist_index
  layout = Object.new.extend(T('layout'))
  Templates::Engine.with_serializer('_todolist.html', options.serializer) do
    options.object = todolist_index_object
    # explode_now
    T('layout').run(options)
  end
end

def todolist_index_object
  # @note we should synthesize some suitable object to render.
  # @think how to set an object type?
  #   But to place an :alltodos tag somewhere is DRY enough for now.
  # @return the first object that has an :alltodos tag.
  all = YARD::Registry.all.select{|codo| codo.has_tag? :alltodos }
  return nil if all.empty?
  object = all[0]
  # @todo override path or something to get a clear serialized_path
end

def generate_todolist_list
  @items = todolist_items
  @list_class = "class" # no own style sheet
  @list_title = "Undone"
  # note: list_type must match some things:
  # - the template file: <erbarg>_<@list_type>.erb
  # - the search list registration type
  @list_type = 'todolist'
  asset('todolist_list.html', erb(:full_list)) # contains something like a frame
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


