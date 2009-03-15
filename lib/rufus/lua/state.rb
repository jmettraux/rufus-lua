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
  # An error class for this gem/library.
  #
  class LuaError < RuntimeError; end

  #
  # Rufus::Lua::Lib contains all the raw C API Lua methods. The methods
  # here are shared by all the rufus-lua classes that have to deal with
  # a Lua state. They are protected since they aren't meant to be called
  # directly.
  #
  # The entry point of rufus-lua is Rufus::Lua::State, look there.
  #
  module StateMixin

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

    protected

    #
    # This method holds the 'eval' mechanism.
    #
    def loadstring_and_call (s)

      bottom = stack_top

      err = Lib.luaL_loadbuffer(@pointer, s, Lib.strlen(s), 'line')
      raise_if_error('eval:compile', err)

      pcall(bottom, 0) # arg_count is set to 0
    end

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
    def print_stack (msg=nil)

      puts "\n=stack= #{msg ? "(#{msg})" : ""}"
      puts "top : #{stack_top}"
      print stack_to_s
      puts "= ="
    end

    #
    # Returns the offset (int) of the top element of the stack.
    #
    def stack_top

      #t = Lib.lua_gettop(@pointer)
      #t < 0 ? 0 : t
      #t
      Lib.lua_gettop(@pointer)
    end

    #
    # Returns a pair type (int) and type name (string) of the element on top
    # of the Lua state's stack. There is an optional pos paramter to peek
    # at other elements of the stack.
    #
    def stack_type_at (pos=-1)

      type = Lib.lua_type(@pointer, pos)
      tname = Lib.lua_typename(@pointer, type)

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

        when TSTRING then Lib.lua_tolstring(@pointer, pos, nil)
        when TBOOLEAN then (Lib.lua_toboolean(@pointer, pos) == 1)
        when TNUMBER then Lib.lua_tonumber(@pointer, pos)

        when TTABLE then Table.new(@pointer)
        when TFUNCTION then Function.new(@pointer)
        when TTHREAD then Coroutine.new(@pointer)

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

      new_top = stack_top - 1
      new_top = 0 if new_top < 0
      Lib.lua_settop(@pointer, new_top)
    end

    #
    # Given a Ruby instance, will attempt to push it on the Lua stack.
    #
    def stack_push (o)

      case o

        when NilClass then Lib.lua_pushnil(@pointer)

        when TrueClass then Lib.lua_pushboolean(@pointer, 1)
        when FalseClass then Lib.lua_pushboolean(@pointer, 1)

        when Fixnum then Lib.lua_pushinteger(@pointer, o)
        when Float then Lib.lua_pushnumber(@pointer, o)

        when String then Lib.lua_pushstring(@pointer, o)

        else raise(
          ArgumentError.new(
            "don't know how to pass Ruby instance of #{o.class} to Lua"))
      end
    end

    #
    # Loads a Lua global value on top of the stack
    #
    def stack_load_global (name)

      Lib.lua_getfield(@pointer, LUA_GLOBALSINDEX, name)
    end

    #
    # Loads the Lua object registered with the given ref on top of the stack
    #
    def stack_load_ref (ref)

      #stack_push(nil) if stack_top < 0
      #while (stack_top < 0) do stack_push(nil); end

      Lib.lua_rawgeti(@pointer, LUA_REGISTRYINDEX, @ref)
    end

    #
    # Returns the result of a function call or a coroutine.resume().
    #
    def return_result (stack_bottom)

      count = stack_top - stack_bottom

      return nil if count == 0
      return stack_pop if count == 1

      (1..count).collect { |pos| stack_pop }.reverse
    end

    #
    # Assumes the Lua stack is loaded with a ref to a method and arg_count
    # arguments (on top of the method), will then call that Lua method and
    # return a result.
    #
    # Will raise an error in case of failure.
    #
    def pcall (stack_bottom, arg_count)

      #err = Lib.lua_pcall(@pointer, 0, 1, 0)
        # when there's only 1 return value, use LUA_MULTRET (-1) the
        # rest of the time

      err = Lib.lua_pcall(@pointer, arg_count, LUA_MULTRET, 0)
      raise_if_error('eval:pcall', err)

      return_result(stack_bottom)
    end

    #--
    # Resumes a coroutine (that has been placed, under its arguments,
    # on top of the stack).
    #
    #def do_resume (stack_bottom, arg_count)
    #  err = Lib.lua_resume(@pointer, arg_count)
    #  raise_if_error('eval:resume', err)
    #  return_result(stack_bottom)
    #end
    #++

    #
    # This method will raise an error with err > 0, else it will immediately
    # return.
    #
    def raise_if_error (where, err)

      return if err < 1

      # TODO :
      #
      # LUA_ERRRUN: a runtime error.
      # LUA_ERRMEM: memory allocation error. For such errors, Lua does not call
      #   the error handler function.
      # LUA_ERRERR: error while running the error handler function.

      s = Lib.lua_tolstring(@pointer, -1, nil)
      Lib.lua_settop(@pointer, -2)

      raise LuaError.new("#{where} : '#{s}' (#{err})")
    end

    #
    # Given the name of a Lua global variable, will return its value (or nil
    # if there is nothing bound under that name).
    #
    def get_global (name)

      stack_load_global(name)
      stack_pop
    end
  end

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
    include StateMixin

    #
    # Instantiates a Lua state (runtime).
    #
    # Accepts an 'include_libs' optional arg. When set to true (the default,
    # all the base Lua libs are loaded in the runtime.
    #
    def initialize (include_libs=true)

      @pointer = Lib.luaL_newstate

      Lib.luaL_openlibs(@pointer) if include_libs
    end

    #
    # Evaluates a piece (string) of Lua code within the state.
    #
    def eval (s)

      loadstring_and_call(s)
    end

    #
    # Returns a value set at the 'global' level in the state.
    #
    #   state.eval('a = 1 + 2')
    #   puts state['a'] # => "3.0"
    #
    def [] (k)

      k.index('.') ? self.eval("return #{k}") : get_global(k)
    end

    #
    # Closes the state.
    #
    # It's probably a good idea (mem leaks) to close a Lua state once you're
    # done with it.
    #
    def close

      Lib.lua_close(@pointer)
    end

    #def _G
    #  get_global('_G')
    #end
    #alias :global_env :_G
  end
end

