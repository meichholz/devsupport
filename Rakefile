load File.join(File.dirname(__FILE__), 'tasks', 'setup.rb')

ds_configure do |c|
  c.editfiles = Dir["tasks/**.rb", 'yard/**.*rb'].join(" ")
end

ds_tasks_for :ruby

task :yardopt do
  File.open(File.dirname(__FILE__)+"/.yardopts", "w") do |f|
    f.puts <<EOM
--markup=markdown
--main=README.md
--protected
--private
--hide-void-return
--default-return Unknown
EOM
  f.puts '-e '+File.dirname(__FILE__)+'/yard/standard/plugin.rb'
  f.puts <<EOM
tasks/setup.rb
yard/**/*.rb
EOM
  end
end

task 'doc:build' => [ :yardopt ]

