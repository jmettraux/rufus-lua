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

  #
  # An error class for rufus-lua.
  #
  class LuaError < RuntimeError

    attr_reader :kind, :errcode, :msg, :file, :line

    def initialize(kind, errcode, msg)

      @kind = kind
      @errcode = errcode
      @msg = msg
      @file, @line = determine_file_and_line

      super(
        "#{@kind} : '#{@msg}' (#{@errcode}) #{File.basename(@file)}:#{@line}")
    end

    protected

    CALLER_REX = /^(.+):(\d+):/
    DIR = File.dirname(__FILE__)

    def determine_file_and_line

      caller.each do |line|
        m = CALLER_REX.match(line)
        return [ m[1], m[2].to_i ] if m && File.dirname(m[1]) != DIR
      end

      [ '', -1 ]
    end
  end
end

