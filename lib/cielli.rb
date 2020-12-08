#
  Object.send(:remove_const, :Cielli) if Object.const_defined?(:Cielli)

#
  require 'json'
  require 'yaml'
  require 'base64'
  require 'securerandom'
  require 'fileutils'
  require 'pathname'
  require 'set'
  require 'openssl'
  require 'uri'
  require 'cgi'
  require 'shellwords'
  require 'tmpdir'
  require 'tempfile'
  require 'pp'
  require 'open3'

#
  require_relative 'cielli/_lib'

#
  class Cielli
    attr_accessor :source
    attr_accessor :root
    attr_accessor :env
    attr_accessor :argv
    attr_accessor :stdout
    attr_accessor :stdin
    attr_accessor :stderr
    attr_accessor :help

    def run!(env = ENV, argv = ARGV)
      init!(env, argv)
      parse_command_line!
      set_mode!
      run_mode!
    end

    def init!(env, argv)
      @klass = self.class
      @env = env.to_hash.dup
      @argv = argv.map{|arg| arg.dup}
      @stdout = $stdout.dup
      @stdin = $stdin.dup
      @stderr = $stderr.dup
      @help = @klass.help || utils.unindent(EXAMPLE_HELP)
    end

    EXAMPLE_HELP = <<-__
      NAME
        #TODO

      SYNOPSIS
        #TODO
         
      DESCRIPTION
        #TODO
         
      EXAMPLES
        #TODO
    __

    def parse_command_line!
      @options = Hash.new

      argv = []
      head = []
      tail = []

      %w[ :: -- ].each do |stop|
        if((i = @argv.index(stop)))
          head = @argv.slice(0 ... i)
          tail = @argv.slice((i + 1) ... @argv.size) 
          @argv = head
          break
        end
      end

      @argv.each do |arg|
        case
          when arg =~ %r`^\s*:([^:\s]+)[=](.+)`
            key = $1
            val = $2
            @options[key] = val
          when arg =~ %r`^\s*(:+)(.+)`
            leader = $1
            key = $2
            val = leader.size.odd?
            @options[key] = val
          else
            argv.push(arg)
        end
      end

      argv += tail

      @argv.replace(argv)
    end

    def set_mode!
      case
        when respond_to?("run_#{ @argv[0] }")
          @mode = @argv.shift
        else
          @mode = nil
      end
    end

    def run_mode!
      if @mode
        return send("run_#{ @mode }")
      else
        if respond_to?(:run)
          return send(:run)
        end

        if @argv.empty?
          run_help!
        else
          abort("#{ $0 } help")
        end
      end
    end

    def run_help!
      STDOUT.puts(@help)
    end

    def help!
      run_help!
      abort
    end

  #
    def Cielli.help(*args)
      @help ||= nil

      unless args.empty?
        @help = utils.unindent(args.join)
      end

      @help
    end

    def Cielli.run(*args, &block)
      modes =
        if args.empty?
          [nil]
        else
          args
        end

      modes.each do |mode|
        method_name =
          if mode
            "run_#{ mode }"
          else
            "run"
          end

        define_method(method_name, &block)
      end
    end

  #
    def Cielli.klass_for(&block)
      Class.new(Cielli) do |klass|
        def klass.name; "Cielli::Klass__#{ SecureRandom.uuid.to_s.gsub('-', '_') }"; end
        klass.class_eval(&block)
      end
    end

    def Cielli.run!(*args, &block)
      STDOUT.sync = true
      STDERR.sync = true

      %w[ PIPE INT ].each{|signal| Signal.trap(signal, "EXIT")}

      cielli = (
        source = 
          if binding.respond_to?(:source_location)
            File.expand_path(binding.source_location.first)
          else
            File.expand_path(eval('__FILE__', block.binding))
          end

        root = File.dirname(source)

        klass = Cielli.klass_for(&block)

        instance = klass.new

        instance.source = source

        instance.root = root

        instance
      )

      cielli.run!(*args)
    end
  end

#
  require_relative 'cielli/utils'

  def Cielli.utils(&block)
    block ? Cielli::Utils.module_eval(&block) : Cielli::Utils
  end

  def Cielli.u(&block)
    Cielli.utils(&block)
  end

  def utils
    Cielli::Utils
  end

  def u
    Cielli::Utils
  end

#
  class << self
    def cielli(*args, &block)
      Cielli.run!(*args, &block)
    end
    
    alias_method :cli, :cielli
  end
