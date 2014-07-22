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
    LUA_NOREF = -2
    LUA_REFNIL = -1

    # Lua GC constants
    LUA_GCSTOP = 0
    LUA_GCRESTART = 1
    LUA_GCCOLLECT = 2
    LUA_GCCOUNT = 3
    LUA_GCCOUNTB = 4
    LUA_GCSTEP = 5
    LUA_GCSETPAUSE = 6
    LUA_GCSETSTEPMUL = 7

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

    SIMPLE_TYPES = [ TNIL, TBOOLEAN, TNUMBER, TSTRING ]

    LUA_MULTRET = -1

    protected

    # This method is used to fetch/cache references to library methods like
    # 'math.sin' or 'coroutine.resume'.
    # The caching is done at the Lua state level (ie, all Lua objects available
    # via the state share the cache.
    #
    # (Not sure yet about this yet)
    #
    def fetch_library_method(s)

      m = @pointer.__lib_method_cache[s]
      return m if m

      @pointer.__lib_method_cache[s] =
        loadstring_and_call("return #{s}", nil, nil, nil)
    end

    # This method holds the 'eval' mechanism.
    #
    def loadstring_and_call(s, binding, filename, lineno)

      bottom = stack_top
      chunk = filename ? "#{filename}:#{lineno}" : 'line'

      err = Lib.luaL_loadbuffer(@pointer, s, Lib.strlen(s), chunk)
      fail_if_error('eval:compile', err, binding, filename, lineno)

      pcall(bottom, 0, binding, filename, lineno) # arg_count is set to 0
    end

    # Returns a string representation of the state's stack.
    #
    def stack_to_s

      # warning : don't touch at stack[0]

      s = (1..stack_top).inject([]) { |a, i|

        type, tname = stack_type_at(i)

        val = if type == TSTRING
          "\"#{stack_fetch(i)}\""
        elsif SIMPLE_TYPES.include?(type)
          stack_fetch(i).to_s
        elsif type == TTABLE
          "(# is #{Lib.lua_objlen(@pointer, i)})"
        else
          ''
        end

        a << "#{i} : #{tname} (#{type}) #{val}"
        a
      }.reverse.join("\n")

      s += "\n" if s.length > 0

      s
    end

    # Outputs the stack to the stdout
    #
    def print_stack(msg=nil)

      puts "\n=stack= #{msg ? "(#{msg})" : ""}"
      puts "top : #{stack_top}"
      print stack_to_s
      puts "= ="
    end

    # Returns the offset (int) of the top element of the stack.
    #
    def stack_top

      Lib.lua_gettop(@pointer)
    end

    # Returns a pair type (int) and type name (string) of the element on top
    # of the Lua state's stack. There is an optional pos paramter to peek
    # at other elements of the stack.
    #
    def stack_type_at(pos=-1)

      type = Lib.lua_type(@pointer, pos)
      tname = Lib.lua_typename(@pointer, type)

      [ type, tname ]
    end

    # Fetches the top value on the stack (or the one specified by the optional
    # pos parameter), but does not 'pop' it.
    #
    def stack_fetch(pos=-1)

      type, tname = stack_type_at(pos)

      case type

        when TNIL then nil

        when TSTRING then
          len = FFI::MemoryPointer.new(:size_t)
          ptr = Lib.lua_tolstring(@pointer, pos, len)
          ptr.read_string(len.read_long)

        when TBOOLEAN then (Lib.lua_toboolean(@pointer, pos) == 1)
        when TNUMBER then Lib.lua_tonumber(@pointer, pos)

        when TTABLE then Table.new(@pointer)
          # warning : this pops up the item from the stack !

        when TFUNCTION then Function.new(@pointer)
        when TTHREAD then Coroutine.new(@pointer)

        else tname
      end
    end

    # Pops the top value of lua state's stack and returns it.
    #
    def stack_pop

      r = stack_fetch
      stack_unstack if r.class != Rufus::Lua::Table

      r
    end

    # Makes sure the stack loses its top element (but doesn't return it).
    #
    def stack_unstack

      new_top = stack_top - 1
      new_top = 0 if new_top < 0
        #
        # there are no safeguard in Lua, setting top to -2 work well
        # when the stack is crowded, but it has bad side effects when the
        # stack is empty... Now safeguarding by ourselves.

      Lib.lua_settop(@pointer, new_top)
    end

    # Given a Ruby instance, will attempt to push it on the Lua stack.
    #
    def stack_push(o)

      return stack_push(o.to_lua) if o.respond_to?(:to_lua)

      case o

        when NilClass then Lib.lua_pushnil(@pointer)

        when TrueClass then Lib.lua_pushboolean(@pointer, 1)
        when FalseClass then Lib.lua_pushboolean(@pointer, 0)

        when Fixnum then Lib.lua_pushinteger(@pointer, o)
        when Float then Lib.lua_pushnumber(@pointer, o)

        when String then Lib.lua_pushlstring(@pointer, o, o.bytesize)
        when Symbol then Lib.lua_pushlstring(@pointer, o.to_s, o.to_s.bytesize)

        when Hash then stack_push_hash(o)
        when Array then stack_push_array(o)

        else raise(
          ArgumentError.new(
            "don't know how to pass Ruby instance of #{o.class} to Lua"))
      end
    end

    # Pushes a hash on top of the Lua stack.
    #
    def stack_push_hash(h)

      Lib.lua_createtable(@pointer, 0, h.size)
        # since we already know the size of the table...

      h.each do |k, v|
        stack_push(k)
        stack_push(v)
        Lib.lua_settable(@pointer, -3)
      end
    end

    # Pushes an array on top of the Lua stack.
    #
    def stack_push_array(a)

      Lib.lua_createtable(@pointer, a.size, 0)
        # since we already know the size of the table...

      a.each_with_index do |e, i|
        stack_push(i + 1)
        stack_push(e)
        Lib.lua_settable(@pointer, -3)
      end
    end

    # Loads a Lua global value on top of the stack
    #
    def stack_load_global(name)

      Lib.lua_getfield(@pointer, LUA_GLOBALSINDEX, name)
    end

    # Loads the Lua object registered with the given ref on top of the stack
    #
    def stack_load_ref(ref)

      Lib.lua_rawgeti(@pointer, LUA_REGISTRYINDEX, @ref)
    end

    # Returns the result of a function call or a coroutine.resume().
    #
    def return_result(stack_bottom)

      count = stack_top - stack_bottom

      return nil if count == 0
      return stack_pop if count == 1

      (1..count).collect { |pos| stack_pop }.reverse
    end

    # Assumes the Lua stack is loaded with a ref to a method and arg_count
    # arguments (on top of the method), will then call that Lua method and
    # return a result.
    #
    # Will raise an error in case of failure.
    #
    def pcall(stack_bottom, arg_count, binding, filename, lineno)

      #err = Lib.lua_pcall(@pointer, 0, 1, 0)
        # when there's only 1 return value, use LUA_MULTRET (-1) the
        # rest of the time

      err = Lib.lua_pcall(@pointer, arg_count, LUA_MULTRET, @error_handler)
      fail_if_error('eval:pcall', err, binding, filename, lineno)

      return_result(stack_bottom)
    end

    #--
    # Resumes a coroutine (that has been placed, under its arguments,
    # on top of the stack).
    #
    #def do_resume(stack_bottom, arg_count)
    #  err = Lib.lua_resume(@pointer, arg_count)
    #  fail_if_error('eval:resume', err, nil, nil, nil)
    #  return_result(stack_bottom)
    #end
    #++

    # This method will raise an error with err > 0, else it will immediately
    # return.
    #
    def fail_if_error(kind, err, binding, filename, lineno)

      return if err < 1

      s = Lib.lua_tolstring(@pointer, -1, nil).read_string
      Lib.lua_settop(@pointer, -2)

      fail LuaError.new(kind, err, s, binding, filename, lineno)
    end

    # Given the name of a Lua global variable, will return its value (or nil
    # if there is nothing bound under that name).
    #
    def get_global(name)

      stack_load_global(name)
      stack_pop
    end
  end

  class CallbackState
    include StateMixin

    def initialize(pointer)

      @pointer = pointer
      @callbacks = []
      @error_handler = 0
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

    # Instantiates a Lua state (runtime).
    #
    # Accepts an 'include_libs' optional arg. When set to true (the default,
    # all the base Lua libs are loaded in the runtime.
    #
    # This optional arg can be set to false, when no libs should be present, or
    # to an array of libs to load in order to prepare the state.
    #
    # The list may include 'base', 'package', 'table', 'string', 'math', 'io',
    # 'os' and 'debug'.
    #
    def initialize(include_libs=true)

      @pointer = Lib.luaL_newstate

      open_libraries(include_libs)

      #
      # preparing library methods cache

      class << @pointer
        attr_reader :__lib_method_cache
      end
      @pointer.instance_variable_set(:@__lib_method_cache, {})

      #
      # an array for preserving callback (Ruby functions) from Ruby
      # garbage collection (Scott).

      @callbacks = []

      @error_handler = 0
    end

    def set_error_handler(lua_code)

      if lua_code == nil
        @error_handler = 0
        return
      end

      lua_code = 'return ' + lua_code \
        unless lua_code.match(/^return[\s\(]/)

      m = caller[0].match(/([^\\\/]+):(\d+)/)
      chunk, filename, lineno = m[0, 3]

      err = Lib.luaL_loadbuffer(
        @pointer, lua_code, Lib.strlen(lua_code), chunk)
      fail_if_error(
        'eval:compile:error_handler', err, nil, filename, lineno)

      @error_handler = stack_top
    end

    # Evaluates a piece (string) of Lua code within the state.
    #
    def eval(s, binding=nil, filename=nil, lineno=nil)

      loadstring_and_call(s, binding, filename, lineno)
    end

    # Returns a value set at the 'global' level in the state.
    #
    #   state.eval('a = 1 + 2')
    #   puts state['a'] # => "3.0"
    #
    def [](k)

      k.index('.') ?  self.eval("return #{k}") : get_global(k)
    end

    # Allows for setting a Lua varible immediately.
    #
    #   state['var'] = [ 1, 2, 3 ]
    #   puts state['var'].to_a[0] # => 1
    #
    def []=(k, v)

      #puts; puts("#{k} = #{Rufus::Lua.to_lua_s(v)}")
      self.eval("#{k} = #{Rufus::Lua.to_lua_s(v)}")
    end

    # Binds a Ruby function (callback) in the top environment of Lua
    #
    #   require 'rufus/lua'
    #
    #   s = Rufus::Lua::State.new
    #
    #   s.function 'key_up' do |table|
    #     table.inject({}) do |h, (k, v)|
    #       h[k.to_s.upcase] = v
    #     end
    #   end
    #
    #   p s.eval(%{
    #     local table = {}
    #     table['CoW'] = 2
    #     table['pigs'] = 3
    #     table['DUCKS'] = 'none'
    #     return key_up(table)
    #   }).to_h
    #     # => { 'COW' => 2.0, 'DUCKS => 'none', 'PIGS' => 3.0 }
    #
    #   s.close
    #
    # == :to_ruby => true
    #
    # Without this option set to true, Lua tables passed to the wrapped
    # Ruby code are instances of Rufus::Lua::Table. With this option set,
    # rufus-lua will call #to_ruby on any parameter that responds to it
    # (And Rufus::Lua::Table does).
    #
    #   s = Rufus::Lua::State.new
    #
    #   s.function 'is_array', :to_ruby => true do |table|
    #     table.is_a?(Array)
    #   end
    #
    #   s.eval(return is_array({ 1, 2 }))
    #     # => true
    #   s.eval(return is_array({ 'a' = 'b' }))
    #     # => false
    #
    def function(name, opts={}, &block)

      raise 'please pass a block for the body of the function' unless block

      to_ruby = opts[:to_ruby]

      callback = Proc.new do |state|

        s = CallbackState.new(state)
        args = []

        loop do

          break if s.stack_top == 0 # never touch stack[0] !!

          arg = s.stack_fetch
          break if arg.class == Rufus::Lua::Function

          args.unshift(arg)

          s.stack_unstack unless args.first.is_a?(Rufus::Lua::Table)
        end

        while args.size < block.arity
          args << nil
        end

        args = args.collect { |a| a.respond_to?(:to_ruby) ? a.to_ruby : a } \
          if to_ruby

        result = block.call(*args)

        s.stack_push(result)

        1
      end

      @callbacks << callback
        # preserving the callback from garbage collection

      name = name.to_s

      name, index = if ri = name.rindex('.')
        #
        # bind in the given table

        table_name = name[0..ri-1]

        t = self.eval("return #{table_name}") rescue nil

        raise ArgumentError.new(
          "won't create automatically nested tables"
        ) if (not t) and table_name.index('.')

        t = self.eval("#{table_name} = {}; return #{table_name}") \
          unless t

        t.send(:load_onto_stack)

        [ name[ri+1..-1], -2 ]

      else
        #
        # bind function at the global level

        [ name, LUA_GLOBALSINDEX ]
      end

      Lib.lua_pushcclosure(@pointer, callback, 0)
      Lib.lua_setfield(@pointer, index, name)
    end

    # Closes the state.
    #
    # It's probably a good idea (mem leaks) to close a Lua state once you're
    # done with it.
    #
    def close

      raise "State already closed" unless @pointer
      Lib.lua_close(@pointer)
      @pointer = nil
    end

    # Returns current amount of memory in KB in use by Lua
    #
    def gc_count

      raise "State got closed, cannot proceed" unless @pointer
      Lib.lua_gc(@pointer, LUA_GCCOUNT, 0)
    end

    # Runs garbage collection
    #
    def gc_collect!

      raise "State got closed, cannot proceed" unless @pointer
      Lib.lua_gc(@pointer, LUA_GCCOLLECT, 0)
    end

    # Stop garbage collection for this state
    #
    def gc_stop

      raise "State got closed, cannot proceed" unless @pointer
      Lib.lua_gc(@pointer, LUA_GCSTOP, 0)
    end

    # Restart garbage collection for this state
    #
    def gc_resume

      raise "State got closed, cannot proceed" unless @pointer
      Lib.lua_gc(@pointer, LUA_GCRESTART, 0)
    end

    # #open_library(libname) - load a lua library via lua_call().
    #
    # This is needed because is the Lua 5.1 Reference Manual Section 5
    # (http://www.lua.org/manual/5.1/manual.html#5) it says:
    #
    # "The luaopen_* functions (to open libraries) cannot be called
    # directly, like a regular C function. They must be called through
    # Lua, like a Lua function."
    #
    # "..you must call them like any other Lua C function, e.g., by using
    # lua_call."
    #
    # (by Matthew Nielsen - https://github.com/xunker)
    #
    def open_library(libname)

      Lib.lua_pushcclosure(
        @pointer, lambda { |ptr| Lib.send("luaopen_#{libname}", @pointer) }, 0)
      Lib.lua_pushstring(
        @pointer, (libname.to_s == "base" ? "" : libname.to_s))
      Lib.lua_call(
        @pointer, 1, 0)
    end

    def open_libraries(libs)

      if libs == true
        Lib.luaL_openlibs(@pointer)
      elsif libs.is_a?(Array)
        libs.each { |l| open_library(l) }
      end
    end
  end
end

