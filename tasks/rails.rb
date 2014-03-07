# include into Rakefile something like this:
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# prefix = File.exists?('dev_upstream') ? '..' : '.'
# load "#{prefix}/devsupport/tasks/rails_common.rake"
# task :default => .... current target
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# pre-overrides
@editfiles ||= FileList.new("app/controllers/*.rb", "lib/tasks/*.rake", "db/*.rb", "local*.vim")

load File.join(File.dirname(__FILE__), "common.rake")
include Devsupport

# full reset default task
Rake::Task[:default].clear
CLEAN.include "**/*.log", "*~", ".*~", "t", "tt"
CLEAN.include "log/*.log", "tmp/restart.txt"
CLOBBER.include "*.bak", "*..orig"
CLOBBER.include "*.sqlite3", "*.sqlite-journal"
CLOBBER.include "tags", "coverage", "doc"

ENV['RAILS_ENV'] = @devconf
ENV['LOCALE'] = @devlocale

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

  unless Rake::Task[:'dev:startup']
    desc "Startup test session"
    task :startup => [ 'clobber', :'db:reset', :server, :edit, :browser ]
  end

  desc "Start server(s) (app, doc) in terminals"
  task :server do
    sh "#{@terminal} -e 'rails server' &"
    sh "#{@terminal} -e 'bundle exec yard server' &"
    sleep 4
  end

  desc "Start #{@browser} with app, yard etc."
  task :browser do
    sh "#{@browser} http://localhost:3000/#{@app_path} http://localhost:8808 &"
  end

  desc "Rebuild tags file"
  task :tags do
    sh "ctags --Ruby-kinds=+f -R"
  end

  desc "Start editor"
  task :edit => [ :tags, :'log:clear' ] do
    sh "#{@editor} #{@editfiles.join ' '} &"
  end

  desc "all doc tasks"
  task :doc => [ "doc:build", "diagram:all" ] do
    %w[controllers_brief controllers_complete models_brief models_complete].each do |name|
      sh "mv doc/#{name}.svg doc/yard/#{name}.svg"
    end
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
  desc "create Yard documentation"
  task :build do
    sh "rm -rf doc/yard" if File.exists? "doc/yard"
    sh "yard doc"
  end

  desc "View Yard documentation"
  task :view => :build do
    sh "#{@browser} doc/yard/index.html &"
  end
end


