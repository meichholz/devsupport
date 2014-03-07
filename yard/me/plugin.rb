YARD::Tags::Library.define_tag("Please fix this issue", :FIXME)
YARD::Tags::Library.define_tag("Please fix this issue", :fixme)
YARD::Tags::Library.define_tag("Think about this", :think)
YARD::Tags::Library.define_tag("Think about this", :THINK)
YARD::Tags::Library.define_tag("Todo", :todo)
YARD::Tags::Library.define_tag("Todo", :TODO)
YARD::Tags::Library.define_tag("Todo List", :todolist)

# hier muesste man was zum Templating abschauen können:
# https://github.com/lsegal/yard-spec-plugin/blob/master/lib/yard-rspec.rb

YARD::Templates::Engine.register_template_path File.join(File.dirname(__FILE__), 'templates')

