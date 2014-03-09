require 'rake/clean'
require 'socket'
require 'ostruct'

module Devsupport

  module DSL
    def ds_tasks_for(modulename)
      Devsupport::Rake.load_tasks_for(modulename)
    end
    def ds_env
      return Devsupport::Rake.options
    end
    def ds_raker
      Devsupport::Rake
    end
    def ds_configure(opt={}, &block)
      Devsupport::Rake.configure(opt, &block)
    end
  end

  class Rake
    class << self

      def opt(key)
        option_hash.fetch(key, nil)
      end

      # should be used just by near friends
      # @deprecated
      def option_hash
        @defaults.merge(@customs)
      end

      def options
        OpenStruct.new(option_hash)
      end

      def command?(command)
        system("which #{command} > /dev/null 2>&1")
      end

      def configure(opt={})
        override = opt.fetch(:override, true)
        target = opt.fetch(:defaults, false) ? @defaults : @customs
        newopt = OpenStruct.new(@customs)
        yield(newopt)
        newopt.marshal_dump.each do |key,value|
          if override
            target[key] = value
          else
            target[key] ||= value
          end
        end
      end

      def best_command(*args)
        args.flatten.each do |cmd|
          return cmd if command?(cmd)
        end
        nil
      end

      def setup_package_task(gemspecname=nil)
        gemspecname ||= "#{opt(:program_name)}.gemspec"
        if File.exists?(gemspecname)
          spec=eval(File.read(gemspecname))
          Gem::PackageTask.new(spec) { }
        end
      end

      # @return [True] when full setup is possible
      def have_rvm?
        return true unless ds_env.rvm_only
        unless ENV['GEM_PATH'] and ENV['GEM_PATH']=~/\.rvm/
          STDERR.puts "WARNING: please develop with RVM for the development GEMs"
          STDERR.puts "WARNING: falling back to provision only functionality"
          return FALSE
        end
        return true
      end

      def load_tasks_for(modulename)
        file = File.join(File.dirname(__FILE__), modulename.to_s+".rb")
        # puts "DEBUG: loading #{modulename} from #{file}"
        load file
      end

      def reload_self
        file = upstream_file(__FILE__)
        # try to figure out, how far we must get up to find software root
        # TODO: This may be done somewhat cleaner and more portable...
        if File.exists? opt(:upstream_semaphore)
          puts "INFO: reloading #{file}"
          load file
        end
      end

      private

      def base_path
        File.dirname(File.dirname(__FILE__)) # eliminate "tasks"
      end

      def upstream_file(file)
        file = file.gsub(/^.*devsupport/, 'devsupport')
        if Dir.pwd =~ /\/(trunk|gems)\//
          file = File.join('..', '..', file)
        else
          file = File.join('..', file)
        end
      end

      def defaults
        {
          editor: "gvim -geometry 88x55+495-5",
          devlocale: 'de_DE.UTF-8',
          devconf: :development,
          terminal: best_command(%w(terminal xfce4-terminal gnome-terminal xterm)),
          browser: best_command(%w(epiphany iceweasel firefox konqueror www-browser x-www-browser epiphany)),
          hostname: Socket.gethostname,
          root?: (Process.uid == 0),
          rdoc: "rdoc",
          ronn: "ronn",
          base_path: base_path,
          upstream_semaphore: 'dev_upstream',
        }
      end
    end

    @customs = Hash.new
    @defaults = defaults
  end
end

unless @_devsupport_is_reloaded
  @_devsupport_is_reloaded = true
  Devsupport::Rake.reload_self
end
include Devsupport::DSL
@have_devsupport = true

