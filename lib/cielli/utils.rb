class Cielli
  module Utils
    def unindent(arg)
      string = arg.to_s.dup
      margin = nil
      string.each_line do |line|
        next if line =~ %r/^\s*$/
        margin = line[%r/^\s*/] and break
      end
      string.gsub!(%r/^#{ margin }/, "") if margin
      margin ? string : nil
    end

    def indent(arg, *args)
      opts = extract_options!(args)
      n = (args.shift || opts[:n] || 2).to_i

      string = unindent(arg)

      indentation = ' ' * n

      string.gsub(/^/, indentation)
    end

    def esc(*args)
      args.flatten.compact.map{|arg| Shellwords.escape(arg)}.join(' ')
    end

    def uuid
      SecureRandom.uuid
    end

    def tmpname(*args)
      opts = extract_options!(*args)

      base = opts.fetch(:base){ uuid }.to_s.strip
      ext = opts.fetch(:ext){ 'tmp' }.to_s.strip.sub(/^[.]+/, '')
      basename = opts.fetch(:basename){ "#{ base }.#{ ext }" }

      File.join(Dir.tmpdir, basename)
    end

    def tmpfile(*args, &block)
      opts = extract_options!(args)

      path = tmpname(opts)


      tmp = open(path, 'w+')
      tmp.binmode
      tmp.sync = true

      unless args.empty?
        src = args.join
        tmp.write(src)
        tmp.flush
        tmp.rewind
      end

      if block
        begin
          block.call(tmp)
        ensure
          FileUtilss.rm_rf(path)
        end
      else
        at_exit{ Kernel.system("rm -rf #{ esc(path) }") }
        return tmp
      end
    end

    def extract_options!(args)
      unless args.is_a?(Array)
        args = [args]
      end

      opts = args.last.is_a?(Hash) ? args.pop : {}

      symbolize_keys!(opts)

      return opts
    end

    def extract_options(args)
      opts = extract_options!(args)

      args.push(opts)

      opts
    end

    def symbolize_keys!(hash)
      hash.keys.each do |key|
        if key.is_a?(String)
          val = hash.delete(key)

          if val.is_a?(Hash)
            symbolize_keys!(val)
          end

          hash[key.to_s.gsub('-', '_').to_sym] = val
        end
      end

      return hash
    end

    def symbolize_keys(hash)
      symbolize_keys!(deepcopy(hash))
    end

    def deepcopy(object)
      Marshal.load(Marshal.dump(object))
    end

    def debug!(arg)
      if arg.is_a?(String)
        warn "[DEBUG] #{ arg }"
      else
        warn "[DEBUG] >\n#{ arg.to_yaml rescue arg.pretty_inspect }"
      end
    end

    def debug(arg)
      debug!(arg) if debug?
    end

    def debug?
      ENV['CIELLI_DEBUG'] || ENV['DEBUG']
    end

    def noop
      ENV['CIELLI_NOOP'] || ENV['NOOP']
    end
    alias_method :noop?, :noop

    def sys!(*args, &block)
      opts = extract_options!(args)

      cmd = args

      debug(:cmd => cmd)

      open3 = (
        block ||
        opts[:stdin] ||
        opts[:quiet] ||
        opts[:capture]
      )

      die = proc do |command, *args|
        status = args.shift || $?
        warn("#{ [command].join(' ') } #=> status=#{ status.exitstatus }") unless opts[:quiet]
        exit(1)
      end

      if(open3)
        stdin = opts[:stdin]
        stdout = ''
        stderr = ''
        status = nil

        begin
          Open3.popen3(*cmd) do |i, o, e, t|
            ot = async_reader_thread_for(o, stdout) 
            et = async_reader_thread_for(e, stderr) 

            i.write(stdin) if stdin
            i.close

            ot.join
            et.join

            status = t.value
          end
        rescue
          die[cmd]
        end

        if status.exitstatus == 0
          result = nil

          if opts[:capture]
            result = stdout.to_s.strip
          else
            if block
              result = block.call(status, stdout, stderr)
            else
              result = [status, stdout, stderr]
            end
          end

          return(result)
        else
          die[cmd, status]
        end
      else
        env = opts[:env] || {}
        argv = [env, *cmd]
        system(*argv) || die[cmd]
        return true
      end
    end

    def sys(*args, &block)
      opts = extract_options!(args)
      opts[:quiet] = true

      args.push(opts)

      begin
        sys!(*args, &block)
      rescue Object
        false
      end
    end

    def async_reader_thread_for(io, accum)
      Thread.new(io, accum) do |i, a|
        Thread.current.abort_on_exception = true

        while true
          buf = i.read(8192)

          if buf
            a << buf
          else
            break
          end
        end
      end
    end

    def realpath(path)
      Pathname.new(path.to_s).expand_path.realpath.to_s
    end

    def filelist(*args, &block)
      accum = (block || proc{ Set.new }).call
      raise ArgumentError.new('accum.class != Set') unless accum.is_a?(Set)

      _ = args.last.is_a?(Hash) ? args.pop : {}

      entries = args.flatten.compact.map{|arg| realpath("#{ arg }")}.uniq.sort

      entries.each do |entry|
        case
          when test(?f, entry)
            file = realpath(entry)
            accum << file

          when test(?d, entry)
            glob = File.join(entry, '**/**')

            Dir.glob(glob) do |_entry|
              case
                when test(?f, _entry)
                  filelist(_entry){ accum }
                when test(?d, entry)
                  filelist(_entry){ accum }
              end
            end
        end
      end

      accum.to_a
    end

    require_relative 'slug.rb'

    def slug_for(*args, &block)
      Slug.for(*args, &block)
    end

    extend Utils
  end
end
