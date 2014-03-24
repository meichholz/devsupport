# wiki: https://mail.ag.freenet.ag/wiki/Tools/Yard
YARD::Tags::Library.define_tag("Please fix this issue", :fixme)
YARD::Tags::Library.define_tag("Think about this", :think)
YARD::Tags::Library.define_tag("Todo", :todo)
YARD::Tags::Library.define_tag("Todo List", :todolist)

# even the shortest path must contain 'default'
YARD::Templates::Engine.register_template_path File.dirname(__FILE__)

# @todo Missing Features
#   * generate _todolist.html
#   * make better Undonelist
#   * render todolist better
#   * find out, how to insert @todolist in "Top Level Namespace" document.


