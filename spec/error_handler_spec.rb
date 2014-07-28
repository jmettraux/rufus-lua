
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

  describe '#set_error_handler' do

    it 'registers a function as error handler' do

      le = nil

      @s.set_error_handler(%{
        function (e)
          return e .. '\\n' .. debug.traceback()
        end
      });

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

    context 'when called with nil' do

      it 'removes the error handler'
    end

    context 'in case of sub-state invocation' do

      it 'uses the parent state error handler'
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

  describe '#set_error_handler(nil)' do

    it 'unsets the current error handler'
  end
end

