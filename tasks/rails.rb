ds_configure(defaults: true) do |c|
  c.editfiles = FileList.new "app/controllers/*.rb",
    "lib/tasks/*.rake",
    "db/*.rb",
    "local*.vim"
  c.app_path = "tools"
  c.yardoc_path = 'doc/yard'
  c.startup_tasks = [ 'clobber', :'db:reset', :server, :edit, :browser ]
end

ds_tasks_for :common

# full reset default task
Rake::Task[:default].clear
CLEAN.include "**/*.log"
CLEAN.include "log/*.log", "tmp/restart.txt"
CLOBBER.include "*.bak", "*..orig"
CLOBBER.include "*.sqlite3", "*.sqlite-journal"
CLOBBER.include "tags", "coverage", "doc"

ENV['RAILS_ENV'] = ds_env.devconf
ENV['LOCALE'] = ds_env.devlocale

desc "prefix: set test environment"
task :te do
  ENV['RAILS_ENV'] = 'test'
end

desc "short: db console"
task :dbc do
  sh "rails dbconsole"
end

task :edit => 'dev:edit'

namespace :dev do

  desc "Startup development session"
  task :startup => ds_env.startup_tasks

  desc "Start server(s) (app, doc) in terminals"
  task :server do
    ds_termsh 'rails server'
    ds_termsh 'bundle exec yard server'
    sleep 4
  end

  desc "Start #{ds_env.browser} with app, yard etc."
  task :browser do
    sh "#{ds_env.browser} http://localhost:3000/#{ds_env.app_path} http://localhost:8808 &"
  end

  desc "Rebuild tags file"
  task :tags do
    sh ds_env.ctags
  end

  desc "Start editor"
  task :edit => [ :tags, :'log:clear' ] do
    sh "#{ds_env.editor} #{ds_env.editfiles.join ' '} &"
  end

  desc "Start script/smoke"
  task :smoke do
    sh "rails runner script/smoke"
  end

  desc "Trigger passenger reload"
  task :reload do
    sh "touch tmp/restart.txt"
  end

end

namespace :doc do
  desc "create all documentation"
  task :build => [ :yard, :'diagram:all' ] do
    %w[controllers_brief controllers_complete models_brief models_complete].each do |name|
      sh "mv doc/#{name}.svg #{ds_env.yardoc_path}/#{name}.svg"
    end
  end

  desc "create yard documentation"
  task :yard do
    sh "rm -rf #{ds_env.yardoc_path}" if File.exists?(ds_env.yardoc_path)
    sh "yard doc"
  end

  desc "View common documentation"
  task :view => :build do
    sh "#{ds_env.browser} file://#{Dir.pwd}/#{ds_env.yardoc_path}/index.html &"
  end
end


