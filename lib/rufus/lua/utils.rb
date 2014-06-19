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

  #--
  # always make sure that the methods here are usable without the need
  # to load liblua.dylib
  #++

  # Turns a Ruby instance into a Lua parseable string representation.
  #
  # Will raise an ArgumentError as soon as something else than a simple
  # Ruby type (or Hash/Array) is passed.
  #
  #   Rufus::Lua.to_lua_s({ 'a' => 'A', 'b' => 2})
  #     #
  #     # => '{ "a": "A", "b": 2 }'
  #
  def self.to_lua_s(o)

    case o

      when String then o.inspect
      when Fixnum then o.to_s
      when Float then o.to_s
      when TrueClass then o.to_s
      when FalseClass then o.to_s

      when Hash then to_lua_table_s(o)
      when Array then to_lua_table_s(o)

      else raise(
        ArgumentError.new(
          "don't how to turning into a Lua string representation "+
          "Ruby instances of class '#{o.class}'"))
    end
  end

  # Turns a Ruby Array or Hash instance into a Lua parseable string
  # representation.
  #
  def self.to_lua_table_s(o)

    s = if o.is_a?(Array)
      o.collect { |e| to_lua_s(e) }
    else
      o.collect { |k, v| "[#{to_lua_s(k)}] = #{to_lua_s(v)}" }
    end

    "{ #{s.join(', ')} }"
  end
end

