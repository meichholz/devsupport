def init
  super
  sections[:layout].insert(0, :navbar)
end

def navbar
  @items = Array.new
  @items << { href: "index.html", label: "Home", }
  if have_todos?
    @items << { href: "_todolist.html", label: "Todo List", }
  end
  out = erb(:navbar)
  @items = nil
  out
end

def have_todos?
  YARD::Registry.all.each do |codo|
    rc = false
    rc ||= codo.has_tag?(:todo)
    rc ||= codo.has_tag?(:fixme)
    rc ||= codo.has_tag?(:think)
    return true if rc
  end
  false
end

def menu_lists
  super + [ { type: 'todolist', title: 'Todo List', search_title: 'Undone List' } ]
  # @note ``type: 'x'`` refers to the generator method ``generate_x_list``
  #   in ``fulldoc/html/setup.rb``
end
