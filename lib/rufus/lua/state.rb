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
require 'rufus/lua/table'


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
    # have a peek at the Lua runtime as a C thing.
    #
    attr_reader :state

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
    # Evaluates a piece (string) of Lua code within the state.
    #
    def eval (s)

      err = Lib.luaL_loadbuffer(@state, s, Lib.strlen(s), 'line')
      raise_if_error('eval:compile', err)

      #err = Lib.lua_pcall(@state, 0, 1, 0)
      err = Lib.lua_pcall(@state, 0, LUA_MULTRET, 0)
      raise_if_error('eval:call', err)

      stack_fetch
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

    #def method_missing (m, *args)
    #  get_global(m.to_s)
    #  #super
    #end

    #
    # Returns a value set at the 'global' level in the state.
    #
    #   state.eval('a = 1 + 2')
    #   puts state['k'] # => "3.0"
    #
    # note that
    #
    #   puts state.k # => "3.0"
    #
    def [] (k)
      if k.index('.')
        eval("_ = #{k}")
        k = '_'
      end
      get_global(k)
    end

    #def _G
    #  get_global('_G')
    #end
    #alias :global_env :_G

    #def []= (k, v)
    #end

    def stack_to_s
      (1..top).inject([]) { |a, i|
        type, tname = type_at(i)
        a << "#{i} : #{tname} (#{type})"
        a
      }.reverse.join("\n")
    end

    def stack_top
      Lib.lua_gettop(@state)
    end

    def stack_type_at (pos=-1)
      type = Lib.lua_type(@state, pos)
      tname = Lib.lua_typename(@state, type)
      [ type, tname ]
    end

    def stack_fetch (pos=-1)
      type, tname = stack_type_at(pos)
      case type
        when TNIL then nil
        when TSTRING then Lib.lua_tolstring(@state, pos, nil)
        when TBOOLEAN then (Lib.lua_toboolean(@state, pos) == 1)
        when TNUMBER then Lib.lua_tonumber(@state, pos)
        when TTABLE then Table.to_h(self)
        #when TTABLE then Table.new(self, parent)
        else tname
      end
    end

    def stack_pop
      r = stack_fetch
      stack_unstack
      r
    end

    def stack_unstack
      Lib.lua_settop(@state, -2)
    end

    protected

    GLOBALS_INDEX = -10002

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
      s = Lib.lua_tolstring(@state, -1, nil)
      Lib.lua_settop(@state, -2)
      raise "#{where} : '#{s}' (#{err})"
    end

    def get_global (name)
      Lib.lua_getfield(@state, GLOBALS_INDEX, name)
      stack_pop
    end
  end
end

