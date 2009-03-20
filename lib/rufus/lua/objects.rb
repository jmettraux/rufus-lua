#--
# Copyright (c) 2009, John Mettraux, Alain Hoang.
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
    include StateMixin

    #
    # The reference in the Lua registry.
    # (You shouldn't care about this value)
    #
    attr_reader :ref

    def initialize (pointer)

      @pointer = pointer
      @ref = Lib.luaL_ref(@pointer, LUA_REGISTRYINDEX)
        # this pops the object out of the stack !
    end

    #
    # Frees the reference to this object
    # (Problably a good idea if you want Lua's GC to get rid of it later).
    #
    def free
      Lib.luaL_unref(@pointer, LUA_REGISTRYINDEX, @ref)
      @ref = nil
    end

    protected

    #
    # Brings the referenced object on top of the stack (will probably
    # then take part in a method call).
    #
    def load_onto_stack

      raise LuaError.new(
        "#{self.class} got freed, cannot re-access it directly"
      ) unless @ref

      stack_load_ref(@ref)
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

      bottom = stack_top

      load_onto_stack
        # load function on stack

      args.each { |arg| stack_push(arg) }
        # push arguments on stack

      pcall(bottom, args.length)
    end
  end

  #
  # (coming soon)
  #
  class Coroutine < Ref

    #
    # Resumes the coroutine
    #
    def resume (*args)

      bottom = stack_top

      fetch_library_method('coroutine.resume').load_onto_stack

      load_onto_stack
      args.each { |arg| stack_push(arg) }

      pcall(bottom, args.length + 1)
    end

    #
    # Returns the string status of the coroutine :
    # suspended/running/dead/normal
    #
    def status

      bottom = stack_top

      fetch_library_method('coroutine.status').load_onto_stack
      load_onto_stack

      pcall(bottom, 1)
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
    include Enumerable

    #
    # The classical 'each'.
    #
    # Note it cheats by first turning the table into a Ruby Hash and calling
    # the each of that Hash instance (this way, the stack isn't involved
    # in the iteration).
    #
    def each

      return unless block_given?
      self.to_h.each { |k, v| yield(k, v) }
    end

    #
    # Returns the array of keys of this Table.
    #
    def keys

      self.to_h.keys
    end

    #
    # Returns the array of values in this Table.
    #
    def values

      self.to_h.values
    end

    #
    # Returns the value behind the key, or else nil.
    #
    def [] (k)

      load_onto_stack # table
      stack_push(k) # key
      Lib.lua_gettable(@pointer, -2) # fetch val for key at top and table at -2
      stack_pop
    end

    #--
    # TODO : implement (maybe)
    #
    #def []= (k, v)
    #  raise 'not yet !'
    #end
    #++

    #
    # Returns a Ruby Hash instance representing this Lua table.
    #
    def to_h

      load_onto_stack

      table_pos = stack_top

      Lib.lua_pushnil(@pointer)

      h = {}

      while Lib.lua_next(@pointer, table_pos) != 0 do

        value = stack_fetch(-1)
        value.load_onto_stack if value.is_a?(Ref)

        key = stack_fetch(-2)
        key.load_onto_stack if key.is_a?(Ref)

        stack_unstack # leave key on top

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

