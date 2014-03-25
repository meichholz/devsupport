def init
  super
  sections.place([:global_todolist, :local_todolist]).after(:box_info)
end

def global_todolist
  return "" unless object.has_tag?(:alltodos)
  @searchable = YARD::Registry.all
  @items = Array.new
  generic_todolist YARD::Registry.all, "All Loose Ends"
end

def generic_todolist(codos, label)
  @label = label
  @items = Array.new
  add_todo_items @items, codos, "FIX ME", :fixme
  add_todo_items @items, codos, "To do", :todo
  add_todo_items @items, codos, "Think again", :think
  out = ""
  out = erb(:todolist) unless @items.empty?
  @items = nil
  out
end

def local_todolist
  return "" unless object.has_tag?(:todolist)
  # @todo get all objects under this module/class
  generic_todolist [ object ], "All Loose Ends"
end

def add_todo_items(items, codos, header, tagname)
  tags = Array.new
  codos.each do |codo|
    codo.tags.each do |dtag|
      if dtag.tag_name==tagname.to_s
        tags << dtag
      end
    end
  end
  return nil if tags.empty?
  items << { label: header, tagname: tagname, tags: tags }
end


