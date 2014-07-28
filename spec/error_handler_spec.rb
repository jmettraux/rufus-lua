
#
# Specifying rufus-lua
#
# Tue Jul 22 21:07:10 JST 2014
#

require 'spec_base'


describe 'State and error handler' do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  describe '#set_error_handler(lua_code)' do

    it 'registers a function as error handler' do

      le = nil

      @s.set_error_handler(%{
        function (e)
          return e .. '\\n' .. debug.traceback()
        end
      })

      @s.eval(%{
        function f ()
          error("in f")
        end
      }, nil, 'mystuff.lua', 77)
      begin
        @s.eval('f()', nil, 'mymain.lua', 88)
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.message).to eq(%{
eval:pcall : '[string "mystuff.lua:77"]:3: in f
stack traceback:
	[string "line"]:2: in function <[string "line"]:1>
	[C]: in function 'error'
	[string "mystuff.lua:77"]:3: in function 'f'
	[string "mymain.lua:88"]:1: in main chunk' (2 LUA_ERRRUN)
      }.strip)
    end

    it 'set the error handler in a permanent way' do

      le = nil

      @s.set_error_handler(%{
        function (e)
          return 'something went wrong: ' .. string.gmatch(e, ": (.+)$")()
        end
      })

      begin
        @s.eval('error("a")')
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.msg).to eq('something went wrong: a')

      begin
        @s.eval('error("b")')
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.msg).to eq('something went wrong: b')
    end

    context 'CallbackState' do

      # Setting an error handler on the calling state or even directly
      # on the CallbackState doesn't have any effect.
      # Any error handler seems bypassed.

      it 'bypasses any error handler' do

        e = nil

        @s.set_error_handler(%{
          function (e) return 'bad: ' .. string.gmatch(e, ": (.+)$")() end
        })
        f = @s.function(:do_fail) { fail('in style') }
        begin
          @s.eval('do_fail()')
        rescue Exception => e
        end

        expect(e.class).to eq(RuntimeError)
      end
    end
  end

  describe '#set_error_handler(:traceback)' do

    it 'sets a vanilla debug.traceback() error handler' do

      le = nil

      @s.set_error_handler(:traceback)

      @s.eval(%{
        function f ()
          error("in f")
        end
      }, nil, 'mystuff.lua', 77)
      begin
        @s.eval('f()', nil, 'mymain.lua', 88)
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.message).to eq(%{
eval:pcall : '[string "mystuff.lua:77"]:3: in f
stack traceback:
	[C]: in function 'error'
	[string "mystuff.lua:77"]:3: in function 'f'
	[string "mymain.lua:88"]:1: in main chunk' (2 LUA_ERRRUN)
      }.strip)
    end
  end

  describe '#set_error_handler(:backtrace)' do

    it 'provides a merged Ruby then Lua backtrace' # really?
  end

  describe '#set_error_handler(some_ruby)' do

    it 'sets a Ruby callback as handler'
  end

  describe '#set_error_handler(nil)' do

    it 'unsets the current error handler' do

      le = nil

      # set

      @s.set_error_handler(%{
        function (e)
          return 'something went wrong: ' .. string.gmatch(e, ": (.+)$")()
        end
      })

      begin
        @s.eval('error("a")')
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.msg).to eq('something went wrong: a')

      # unset

      @s.set_error_handler(nil)

      begin
        @s.eval('error("b")')
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.msg).to eq('[string "line"]:1: b')
    end
  end
end

