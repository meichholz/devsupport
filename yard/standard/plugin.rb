module YARD
  # @fixme why is the "descend" todo rendered twice?
  # @fixme layout problem with todo list index file
  # @todo descend objects with the :todolist
  # @fixme do not fail when there is no :alltodos
  # @alltodos
  module StandardPlugin
    module Todos
      def start_plugin
        # wiki: https://mail.ag.freenet.ag/wiki/Tools/Yard
        YARD::Tags::Library.define_tag("Please fix this issue", :fixme)
        YARD::Tags::Library.define_tag("Think about this", :think)
        YARD::Tags::Library.define_tag("Todo", :todo)
        YARD::Tags::Library.define_tag("Todo List", :todolist)
        YARD::Tags::Library.define_tag("Todo List", :alltodos)

        # even the shortest path must contain 'default'
        YARD::Templates::Engine.register_template_path File.dirname(__FILE__)
      end
    end
  end
end

include YARD::StandardPlugin::Todos
start_plugin


