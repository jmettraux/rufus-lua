
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

    it 'flips burgers' do

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
      })
      s = @s.eval('f()')

      #p s
    end
  end

  describe '#set_traceback_error_handler' do

    it 'sets a vanilla Debug.traceback() error handler'
  end
end

