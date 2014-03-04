# include into Rakefile something like this:
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# prefix = File.exists?('dev_upstream') ? '..' : '.'
# load "#{prefix}/devsupport/tasks/rails_common.rake"
# task :default => .... current target
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


# full reset default task
Rake::Task[:default].clear
CLOBBER.include [ "**/*.log", "t", "tt", "tags", "coverage", "doc" ]

@devlocale ||= 'de_DE.UTF-8'
@devconf ||= "development"
@editor ||= 'gvim -geometry 88x55+495-5'

def command?(command)
  system("which #{ command} > /dev/null 2>&1")
end

def first_executable_of(*args)
  args.each do |cmd|
    return cmd if command?(cmd)
  end
end

@hostname=`hostname`.chomp

@terminal = command?("terminal") ? "terminal" : "xfce4-terminal"
@browser ||= first_executable_of "epiphany", "iceweasel", "firefox", "konqueror", "www-browser", "x-www-browser", "epiphany"

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

namespace :dev do

  desc "Startup test session"
  task :startup => [ 'clobber', :'db:reset', :server, :edit, :browser ]
  
  desc "Start server(s) (app, doc) in terminals"
  task :server do
    sh "#{@terminal} -e 'rails server' &"
    sh "#{@terminal} -e 'bundle exec yard server' &"
    sleep 4
  end

  desc "Start #{@browser} with app, yard etc."
  task :browser do
    sh "#{@browser} http://localhost:3000/ http://localhost:8808 &"
  end

  desc "Rebuild tags file"
  task :tags do
    sh "ctags --Ruby-kinds=+f -R"
  end

  desc "Start editor"
  task :edit => :tags do
    editfiles=Dir["lib/tasks/*.rake", "app/controllers/*.rb"]
    sh "#{@editor} #{editfiles.join ' '} &"
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


