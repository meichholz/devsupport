#def init
#    super
#    sections.push :todolist
#end

def menu_lists
  super + [ { type: 'todolist', title: 'Todo List', search_title: 'Undone List' } ]
  # note: "type:" refers to the generator method (generate_x_list)
end
