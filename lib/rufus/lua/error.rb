#--
# Copyright (c) 2009-2014, John Mettraux, Alain Hoang.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


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

