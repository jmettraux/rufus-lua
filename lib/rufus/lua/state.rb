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


require 'rufus/lua/lib'
require 'rufus/lua/utils'
require 'rufus/lua/objects'


module Rufus::Lua

  #
  # A Lua state, wraps a Lua runtime.
  #
  #   require 'rufus/lua'
  #   s = Rufus::Lua::State.new
  #   s.eval "a = 1 + 2"
  #
  #   p s['a'] # => 3.0
  #
  class State

    #
    # Instantiates a Lua state (runtime).
    #
    # Accepts an 'include_libs' optional arg. When set to true (the default,
    # all the base Lua libs are loaded in the runtime.
    #
    def initialize (include_libs=true)

      @state = Lib.luaL_newstate

      Lib.luaL_openlibs(@state) if include_libs
    end

    #
    # have a peek at the Lua runtime as a C thing.
    #
    def pointer

      @state
    end

    #
    # Evaluates a piece (string) of Lua code within the state.
    #
    def eval (s)

      bottom = stack_top

      err = Lib.luaL_loadbuffer(@state, s, Lib.strlen(s), 'line')
      raise_if_error('eval:compile', err)

      pcall(bottom, 0) # arg_count is set to 0
    end

    #
    # Don't call me directly !
    #
    def pcall (stack_bottom, arg_count)

      #err = Lib.lua_pcall(@state, 0, 1, 0)
        # when there's only 1 return value, use LUA_MULTRET (-1) the
        # rest of the time

      err = Lib.lua_pcall(@state, arg_count, LUA_MULTRET, 0)
      raise_if_error('eval:pcall', err)

      count = stack_top - stack_bottom

      return nil if count == 0
      return stack_pop if count == 1

      (1..count).collect { |pos| stack_pop }.reverse
    end

    #
    # Closes the state.
    #
    # It's probably a good idea (mem leaks) to close a Lua state once you're
    # done with it.
    #
    def close

      Lib.lua_close(@state)
    end

    #
    # Returns a value set at the 'global' level in the state.
    #
    #   state.eval('a = 1 + 2')
    #   puts state['k'] # => "3.0"
    #
    def [] (k)

      k.index('.') ?
        self.eval("return #{k}") :
        get_global(k)
    end

    #def _G
    #  get_global('_G')
    #end
    #alias :global_env :_G

    #def []= (k, v)
    #end

    #
    # Returns a string representation of the state's stack.
    #
    def stack_to_s

      # warning : don't touch at stack[0]

      s = (1..stack_top).inject([]) { |a, i|
        type, tname = stack_type_at(i)
        a << "#{i} : #{tname} (#{type})"
        a
      }.reverse.join("\n")
      s += "\n" if s.length > 0
      s
    end

    #
    # Outputs the stack to the stdout
    #
    def print_stack
      puts "\n=s=\n#{stack_to_s}==="
    end

    #
    # Returns the offset (int) of the top element of the stack.
    #
    def stack_top

      Lib.lua_gettop(@state)
    end

    #
    # Returns a pair type (int) and type name (string) of the element on top
    # of the Lua state's stack. There is an optional pos paramter to peek
    # at other elements of the stack.
    #
    def stack_type_at (pos=-1)

      type = Lib.lua_type(@state, pos)
      tname = Lib.lua_typename(@state, type)

      [ type, tname ]
    end

    #
    # Fetches the top value on the stack (or the one specified by the optional
    # pos parameter), but does not 'pop' it.
    #
    def stack_fetch (pos=-1)

      type, tname = stack_type_at(pos)

      case type

        when TNIL then nil

        when TSTRING then Lib.lua_tolstring(@state, pos, nil)
        when TBOOLEAN then (Lib.lua_toboolean(@state, pos) == 1)
        when TNUMBER then Lib.lua_tonumber(@state, pos)

        when TTABLE then Table.new(self)
        when TFUNCTION then Function.new(self)
        when TTHREAD then Coroutine.new(self)

        else tname
      end
    end

    #
    # Pops the top value of lua state's stack and returns it.
    #
    def stack_pop

      r = stack_fetch
      stack_unstack
      r
    end

    #
    # Makes sure the stack loses its top element (but doesn't return it).
    #
    def stack_unstack

      Lib.lua_settop(@state, -2)
      nil
    end

    private

    LUA_GLOBALSINDEX = -10002
    LUA_ENVIRONINDEX = -10001
    LUA_REGISTRYINDEX = -10000

    TNONE = -1
    TNIL = 0
    TBOOLEAN = 1
    TLIGHTUSERDATA = 2
    TNUMBER = 3
    TSTRING = 4
    TTABLE = 5
    TFUNCTION = 6
    TUSERDATA = 7
    TTHREAD = 8

    LUA_MULTRET = -1

    def raise_if_error (where, err)

      return if err < 1

      # TODO :
      #
      # LUA_ERRRUN: a runtime error.
      # LUA_ERRMEM: memory allocation error. For such errors, Lua does not call
      #   the error handler function.
      # LUA_ERRERR: error while running the error handler function.

      s = Lib.lua_tolstring(@state, -1, nil)
      Lib.lua_settop(@state, -2)

      raise "#{where} : '#{s}' (#{err})"
    end

    def get_global (name)
      Lib.lua_getfield(@state, LUA_GLOBALSINDEX, name)
      stack_pop
    end
  end
end

