# see:
# https://github.com/burtlo/yard-cucumber/blob/master/lib/templates/default/fulldoc/html/full_list_stepdefinitions.erb
# http://rubydoc.info/gems/yard/YARD/Registry
# http://rubydoc.info/gems/yard/YARD/CodeObjects/Base
def generate_todolist_list
  @items = Array.new
  @items << { header: "Fixmes", items: todo_item_list(:fixme, :FIXME), }
  @items << { header: "Todos", items: todo_item_list(:todo, :TODO), }
  @items << { header: "Thinks about it", items: todo_item_list(:think, :THINK), }
  @list_class = "class" # no own style sheet
  @list_title = "Loose Ends"
  # note: list_type refers to the template name: full_list_X.erb
  # and to the search list registration type
  @list_type = "todolist"

  asset('todolist_list.html', erb(:full_list))
end

def todo_item_list(*tags)
  YARD::Registry.all.select do |codo|
    rc = false
    tags.each do |tag|
      rc ||= codo.tag(tag)
    end
    rc
  end
end


