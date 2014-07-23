
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

      #@s.send(:print_stack)

      @s.set_error_handler(%{
        function (e)
          return "error " .. e
        end
      });

      #@s.send(:print_stack)

      @s.eval(%{
        function f ()
          error("in f")
        end
      }, nil, 'mystuff.lua', 77)
      begin
        @s.eval('f()', nil, 'mymain.lua', 88)
      rescue Rufus::Lua::LuaError => le
        p le
      #rescue Exception => ex
      #  p ex
      end

      #@s.send(:print_stack)
    end

    context 'when called with nil' do

      it 'removes the error handler'
    end

    context 'in case of sub-state invocation' do

      it 'uses the parent state error handler'
    end
  end

  describe '#set_traceback_error_handler' do

    it 'sets a vanilla Debug.traceback() error handler'
  end
end

