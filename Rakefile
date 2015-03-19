load File.join(File.dirname(__FILE__), 'tasks', 'setup.rb')

ds_configure do |c|
  c.editfiles = Dir["tasks/**.rb", 'yard/**.*rb'].join(" ")
end

ds_tasks_for :ruby

# @todo factor this out with the implementation of the Hoe plugin
file '.yardopts' do
  File.open(File.dirname(__FILE__)+"/.yardopts", "w") do |f|
    f.puts <<EOM
--markup-provider=redcarpet
--markup=markdown
--main=README.md
--protected
--private
--hide-void-return
--default-return Unknown
--files=*.md
EOM
  f.puts '-e '+File.dirname(__FILE__)+'/yard/standard/plugin.rb'
  f.puts <<EOM
tasks/**.rb
EOM
  end
end

# TODO: Diese "nachgelagerte" Dependency scheint nicht rechtzeitig zu feuern.
task 'doc:yard' => [ '.yardopts' ]

