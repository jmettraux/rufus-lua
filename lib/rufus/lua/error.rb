
module Rufus::Lua

  # error codes from 0 to 5
  #
  LUA_ERRS = %w[ 0 LUA_YIELD LUA_ERRRUN LUA_ERRSYNTAX LUA_ERRMEM LUA_ERRERR ]

  #
  # An error class for rufus-lua.
  #
  class LuaError < RuntimeError

    attr_reader :kind, :errcode, :msg
    attr_reader :bndng, :filename, :lineno

    attr_reader :original_backtrace

    def initialize(kind, errcode, msg, bndng, filename, lineno)

      super("#{kind} : '#{msg}' (#{errcode} #{LUA_ERRS[errcode]})")

      @kind = kind
      @errcode = errcode
      @msg = msg

      @bndng = bndng
      @filename = filename
      @lineno = lineno
    end

    def filename

      return @filename if @filename

      m = CALLER_REX.match(backtrace.first || '')
      return m ? m[1] : nil
    end

    def lineno

      return @lineno if @lineno

      m = CALLER_REX.match(backtrace.first || '')
      return m ? m[2].to_i : -1
    end

    def set_backtrace(trace)

      @original_backtrace = trace

      trace =
        trace.select { |line|
          m = CALLER_REX.match(line)
          ( ! m) || File.dirname(m[1]) != DIR
        }

      trace.insert(0, "#{@filename}:#{@lineno}:") if @filename

      super(trace)
    end

    CALLER_REX = /^(.+):(\d+):/
    DIR = File.dirname(__FILE__)
  end
end

