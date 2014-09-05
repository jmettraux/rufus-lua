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


require 'ffi'


module Rufus
module Lua

  module Lib
    extend FFI::Library

    #
    # locate the dynamic library

    paths =
      ENV['LUA_LIB'] ||
        # developer points to the right lib
      (
        Dir.glob('/usr/lib/liblua*.so') +
        Dir.glob('/usr/lib/*/liblua*.so') +
        Dir.glob('/usr/local/lib/liblua*.so') +
        Dir.glob('/opt/local/lib/liblua*.so') +
        Dir.glob('/usr/lib/liblua*.dylib') +
        Dir.glob('/usr/local/lib/liblua*.dylib') +
        Dir.glob('/opt/local/lib/liblua*.dylib')
      )
        # or else we attempt to find it from potential locations

    begin

      ffi_lib_flags(:lazy, :global)

      ffi_lib(paths)

    rescue LoadError => le

      fail RuntimeError.new(
        "Didn't find the Lua dynamic library on your system. " +
        "Set LUA_LIB in your environment if have that library or " +
        "go to https://github.com/jmettraux/rufus-lua to learn how to " +
        "get it. (paths: #{paths.inspect})"
      )
    end

    # Rufus::Lua::Lib.path returns the path to the library used.
    #
    def self.path

      f = ffi_libraries.first

      f ? f.name : nil
    end

    #
    # attach functions

    attach_function :lua_close, [ :pointer ], :void

    attach_function :luaL_openlibs, [ :pointer ], :void

    attach_function :lua_call, [ :pointer, :int, :int ], :void
    %w[ base package string table math io os debug ].each do |libname|
      attach_function "luaopen_#{libname}", [ :pointer ], :void
    end

    attach_function :lua_pcall, [ :pointer, :int, :int, :int ], :int
    #attach_function :lua_resume, [ :pointer, :int ], :int

    attach_function :lua_toboolean, [ :pointer, :int ], :int
    attach_function :lua_tonumber, [ :pointer, :int ], :double
    attach_function :lua_tolstring, [ :pointer, :int, :pointer ], :pointer

    attach_function :lua_type, [ :pointer, :int ], :int
    attach_function :lua_typename, [ :pointer, :int ], :string

    attach_function :lua_gettop, [ :pointer ], :int
    attach_function :lua_settop, [ :pointer, :int ], :void

    attach_function :lua_objlen, [ :pointer, :int ], :int
    attach_function :lua_getfield, [ :pointer, :int, :string ], :pointer
    attach_function :lua_gettable, [ :pointer, :int ], :void

    attach_function :lua_createtable, [ :pointer, :int, :int ], :void
    #attach_function :lua_newtable, [ :pointer ], :void
    attach_function :lua_settable, [ :pointer, :int ], :void

    attach_function :lua_next, [ :pointer, :int ], :int

    attach_function :lua_pushnil, [ :pointer ], :pointer
    attach_function :lua_pushboolean, [ :pointer, :int ], :pointer
    attach_function :lua_pushinteger, [ :pointer, :int ], :pointer
    attach_function :lua_pushnumber, [ :pointer, :double ], :pointer
    attach_function :lua_pushstring, [ :pointer, :string ], :pointer
    attach_function :lua_pushlstring, [ :pointer, :pointer, :int ], :pointer

    attach_function :lua_remove, [ :pointer, :int ], :void
      # removes the value at the given stack index, shifting down all elts above

    #attach_function :lua_pushvalue, [ :pointer, :int ], :void
      # pushes a copy of the value at the given index to the top of the stack
    #attach_function :lua_insert, [ :pointer, :int ], :void
      # moves the top elt to the given index, shifting up all elts above
    #attach_function :lua_replace, [ :pointer, :int ], :void
      # pops the top elt and override the elt at given index with it

    attach_function :lua_rawgeti, [ :pointer, :int, :int ], :void

    attach_function :luaL_newstate, [], :pointer
    attach_function :luaL_loadbuffer, [ :pointer, :string, :int, :string ], :int
    attach_function :luaL_ref, [ :pointer, :int ], :int
    attach_function :luaL_unref, [ :pointer, :int, :int ], :void

    attach_function :lua_gc, [ :pointer, :int, :int ], :int

    callback :cfunction, [ :pointer ], :int
    attach_function :lua_pushcclosure, [ :pointer, :cfunction, :int ], :void
    attach_function :lua_setfield, [ :pointer, :int, :string ], :void
  end
end
end

