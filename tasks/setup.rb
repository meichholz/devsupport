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
    def ds_assert_sanity
      Devsupport::Rake.assert_sanity
    end
    def ds_termsh(*command)
      Devsupport::Rake.sh_in_terminal(wait: false, cmd: command)
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

      # @return [Boolean]
      def command?(command)
        system("which #{command} > /dev/null 2>&1")
      end

      # @return [Self]
      def configure(opt={})
        override = opt.fetch(:override, true)
        target = opt.fetch(:defaults, false) ? @defaults : @customs
        newopt = OpenStruct.new(@defaults)
        yield(newopt)
        newopt.marshal_dump.each do |key,value|
          if override
            target[key] = value
          else
            target[key] ||= value
          end
        end
        return self
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

      def sh_in_terminal(opt={})
        cmd=opt.fetch(:cmd, "echo we_need_some_command")
        wait=opt.fetch(:wait, false)
        sh "#{ds_env.terminal}", "-e", commands.join(' '), wait ? '&' : ''
      end

      # @return [Self]
      def assert_umask
        mask = opt(:mandatory_umask)
        abort "FATAL: Set umask to 0#{mask.to_s(8)}, please" if mask!=:none and mask!=File.umask
        self
      end

      # @return [Self]
      def assert_rvm
        abort "FATAL: You need RVM in GEM_PATH to proceed." unless have_rvm? or not(opt(:rvm_only))
        self
      end

      # put it all together
      # @return [Self]
      def assert_sanity
        assert_umask
        assert_rvm
      end

      # @return [Boolean] True, if RVM is in search path
      def have_rvm?
        unless ENV['GEM_PATH'] and ENV['GEM_PATH']=~/\.rvm/
          return FALSE
        end
        return true
      end

      # @return [Self]
      def load_tasks_for(modulename)
        file = File.join(File.dirname(__FILE__), modulename.to_s+".rb")
        # puts "DEBUG: loading #{modulename} from #{file}"
        load file
        self
      end

      def reload_self
        file = upstream_file(__FILE__)
        # try to figure out, how far we must get up to find software root
        # TODO: This may be done somewhat cleaner and more portable...
        if ENV['DEV_UPSTREAM'] or File.exists?(opt(:upstream_semaphore))
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
        if Dir.pwd =~ /\/(trunk$|gems\/)/
          file = File.join('..', '..', file)
        else
          file = File.join('..', file)
        end
      end

      def defaults
        {
          editor: ENV['DEV_EDITOR'] || "gvim -geometry 88x55+495-5",
          ctags: ENV['DEV_CTAGS'] || "ctags -R --exclude=debian,pkg --Ruby-kinds=+f",
          devlocale: 'de_DE.UTF-8',
          devconf: 'development',
          terminal: ENV['DEV_TERMINAL'] || best_command(%w(terminal xfce4-terminal gnome-terminal xterm)),
          browser: ENV['DEV_BROWSER'] || best_command(%w(epiphany iceweasel firefox konqueror www-browser x-www-browser epiphany)),
          hostname: Socket.gethostname,
          root?: (Process.uid == 0),
          mandatory_umask: :none,
          rdoc: "rdoc",
          ronn: "ronn",
          rvm_only: false,
          base_path: base_path,
          yardoc_path: 'yard',
          yard_options: [],
          startup_tasks: %w(clean edit),
          debug_rake: ENV['DEBUG_RAKE'] ? true : false,
          upstream_semaphore: 'dev_upstream',
          run_arguments: "",
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

