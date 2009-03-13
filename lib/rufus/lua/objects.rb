#--
# Copyright (c) 2009, John Mettraux, jmettraux@gmail.com
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
  # The parent class for Table, Function and Coroutine. Simply holds
  # a reference to the object in the Lua registry.
  #
  class Ref

    def initialize (state)
      @state = state
      @ref = Lib.luaL_ref(@state.pointer, State::LUA_REGISTRYINDEX)
    end

    def free
      #
      # TODO : investigate... is it freeing both ? does the artefact get GCed ?
      #
      Lib.luaL_unref(@state.pointer, State::LUA_REGISTRYINDEX, @ref)
    end

    protected

    def load_onto_stack

      Lib.lua_pushnil(@state.pointer) if @state.stack_top < 1
        # maybe refactor that to State...

      Lib.lua_rawgeti(@state.pointer, State::LUA_REGISTRYINDEX, @ref)
    end
  end

  #
  # A Lua function.
  #
  #   require 'rubygems'
  #   require 'rufus/lua'
  #
  #   s = Rufus::Lua::State.new
  #
  #   f = s.eval(%{
  #     return function (x)
  #       return 2 * x
  #     end
  #   })
  #
  #   f.call(2) # => 4.0
  #
  class Function < Ref

    #
    # Calls the Lua function.
    #
    def call (*args)

      top = @state.stack_top + 1

      load_onto_stack
        # load function on stack

      args.each { |arg| push(arg) }
        # push arguments on stack

      @state.pcall(top, args.length)
    end

    protected

    def push (o)
      case o
        when NilClass then Lib.lua_pushnil(@state.pointer)
        when TrueClass then Lib.lua_pushboolean(@state.pointer, 1)
        when FalseClass then Lib.lua_pushboolean(@state.pointer, 1)
        when Fixnum then Lib.lua_pushinteger(@state.pointer, o)
        when Float then Lib.lua_pushnumber(@state.pointer, o)
        when String then Lib.lua_pushstring(@state.pointer, o)
        else raise "don't know how to pass Ruby instance of #{o.class} to Lua"
      end
    end
  end

  #
  # (coming soon)
  #
  class Coroutine < Ref

    def resume (arg)
    end
  end

  #
  # A Lua table.
  #
  # For now, the only thing you can do with it is cast it into a Hash or
  # an Array (will raise an exception if casting to an Array is not possible).
  #
  # Note that direct manipulation of the Lua table (inside Lua) is not possible
  # (as of now).
  #
  class Table < Ref

    #
    # Returns a Ruby Hash instance representing this Lua table.
    #
    def to_h

      load_onto_stack

      table_pos = @state.stack_top

      Lib.lua_pushnil(@state.pointer)

      h = {}

      while Lib.lua_next(@state.pointer, table_pos) != 0 do

        value = @state.stack_fetch(-1)
        key = @state.stack_fetch(-2)

        @state.stack_unstack

        h[key] = value
      end

      h
    end

    #
    # Returns a Ruby Array instance representing this Lua table.
    #
    # Will raise an error if the 'rendering' is not possible.
    #
    def to_a

      h = self.to_h

      keys = h.keys.sort

      keys.find { |k| not [ Float ].include?(k.class) } &&
        raise("cannot turn hash into array, some keys are not numbers")

      keys.inject([]) { |a, k| a << h[k]; a }
    end

  end
end

