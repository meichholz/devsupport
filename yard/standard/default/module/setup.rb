def init
  super
  sections.place(:todolist).after(:box_info)
end

def todolist
  return unless object.has_tag?(:todolist)
  @items = Array.new
  add_todo_items @items, "FIX ME", :fixme
  add_todo_items @items, "To do", :todo
  add_todo_items @items, "Think again", :think
  out = @items.empty? ? "" : erb(:todolist)
  @items = nil
  out
end

def add_todo_items(items, header, tag)
  codos = todo_codo_list(tag)
  return nil if codos.empty?
  items << { label: header, tag: tag, codos: codos }
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


